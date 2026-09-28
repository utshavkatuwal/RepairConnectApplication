<?php

namespace App\Services\Payments;

use App\Enums\PaymentStatus;
use App\Events\PaymentSuccessful;
use App\Models\Job;
use App\Models\Payment;
use App\Models\PlatformSetting;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class WalletService
{
    public function balance(int $technicianId): float
    {
        return (float) WalletTransaction::where('technician_id', $technicianId)->sum('amount');
    }

    /** Append-only ledger credit. Balance is always derived, never stored. */
    public function credit(int $techId, float $amount, string $type, string $refType, int $refId, ?string $note = null): WalletTransaction
    {
        return DB::transaction(function () use ($techId, $amount, $type, $refType, $refId, $note) {
            $tx = WalletTransaction::create([
                'technician_id' => $techId,
                'type' => $type,
                'reference_type' => $refType,
                'reference_id' => $refId,
                'amount' => $amount,
                'balance_after' => 0,
                'description' => $note,
            ]);
            $tx->update(['balance_after' => $this->balance($techId)]);
            return $tx->fresh();
        });
    }

    public function record(int $techId, float $amount, string $type, string $refType, int $refId, ?string $note = null): WalletTransaction
    {
        return $this->credit($techId, $amount, $type, $refType, $refId, $note);
    }

    public function requestWithdrawal(User $tech, float $amount, string $method, string $account): \App\Models\WithdrawalRequest
    {
        abort_unless($tech->isRole('technician'), 403);
        abort_if($amount <= 0, 422, 'Amount must be positive.');
        abort_unless($this->balance($tech->id) >= $amount, 422, 'Insufficient withdrawable balance.');

        return \App\Models\WithdrawalRequest::create([
            'technician_id' => $tech->id,
            'amount' => $amount,
            'method' => $method,
            'account_identifier' => $account,
            'status' => 'pending',
        ]);
    }

    /** Admin decision with ledger movement only on payout. */
    public function decideWithdrawal(User $admin, \App\Models\WithdrawalRequest $w, string $decision, ?string $note = null): \App\Models\WithdrawalRequest
    {
        abort_unless($admin->isAdmin(), 403);

        return DB::transaction(function () use ($admin, $w, $decision, $note) {
            $locked = \App\Models\WithdrawalRequest::whereKey($w->id)->lockForUpdate()->firstOrFail();
            abort_unless($locked->status === 'pending', 409, 'Withdrawal is no longer pending.');

            if ($decision === 'paid') {
                abort_unless($this->balance($locked->technician_id) >= (float) $locked->amount, 422, 'Insufficient balance.');
                $this->record($locked->technician_id, -((float) $locked->amount), 'withdrawal', get_class($locked), $locked->id, 'Withdrawal payout');
                $locked->update([
                    'status' => 'paid',
                    'processed_by' => $admin->id,
                    'processed_at' => now(),
                    'transaction_reference' => $note,
                ]);
            } elseif ($decision === 'rejected') {
                abort_if(blank($note), 422, 'Rejection reason required.');
                $locked->update([
                    'status' => 'rejected',
                    'processed_by' => $admin->id,
                    'processed_at' => now(),
                    'rejection_reason' => $note,
                ]);
            } else {
                $locked->update(['status' => $decision, 'processed_by' => $admin->id, 'processed_at' => now()]);
            }

            return $locked->fresh();
        });
    }
}
