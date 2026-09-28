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

class PaymentService
{
    public function __construct(private WalletService $wallet) {}

    public function gateway(string $provider): PaymentGateway
    {
        return match ($provider) {
            'esewa' => new EsewaGateway,
            'khalti' => new KhaltiGateway,
            default => abort(422, 'Unknown payment provider.'),
        };
    }

    /**
     * Customer initiates: creates a PENDING payment row keyed by the
     * caller-supplied idempotency key (retries return the same row).
     */
    public function initiate(User $customer, Job $job, string $provider, float $amount, string $key): Payment
    {
        abort_unless($customer->id === $job->customer_id, 403);
        abort_unless($job->status === 'completed', 422, 'Job must be completed before payment.');

        return DB::transaction(function () use ($customer, $job, $provider, $amount, $key) {
            $existing = Payment::where('idempotency_key', $key)->first();
            if ($existing) {
                return $existing;
            }

            $payment = Payment::create([
                'job_id' => $job->id,
                'customer_id' => $customer->id,
                'technician_id' => $job->technician_id,
                'provider' => $provider,
                'idempotency_key' => $key,
                'amount' => $amount,
                'currency' => 'NPR',
                'status' => PaymentStatus::Pending->value,
            ]);

            $intent = $this->gateway($provider)->create([
                'idempotency_key' => $key,
                'amount' => $amount,
            ]);
            $payment->update([
                'provider_transaction_id' => $intent['provider_ref'] ?? null,
                'status' => PaymentStatus::Initiated->value,
                'metadata' => $intent,
            ]);

            return $payment->fresh();
        });
    }

    /**
     * Webhook/callback entry: verifies with the provider FIRST, then
     * settles exactly once (unique provider_transaction_id). Duplicate
     * deliveries return the existing row — never double-credit.
     */
    public function handleCallback(string $provider, array $payload): Payment
    {
        $result = $this->gateway($provider)->verify($payload);

        return DB::transaction(function () use ($provider, $result) {
            $payment = Payment::where('provider_transaction_id', $result['provider_ref'])
                ->lockForUpdate()
                ->first();

            abort_unless($payment, 404, 'Unknown provider transaction.');
            if (in_array($payment->status, ['successful', 'refunded'], true)) {
                return $payment; // idempotent replay
            }

            if (($result['status'] ?? null) === 'successful') {
                $this->settle($payment);
            } else {
                $payment->update(['status' => PaymentStatus::Failed->value]);
            }

            return $payment->fresh();
        });
    }

    /**
     * Settle: commission from platform_settings, ledger credit, notify.
     * All inside the caller's transaction.
     */
    public function settle(Payment $payment): Payment
    {
        abort_unless(
            in_array($payment->status, ['pending', 'initiated', 'processing'], true),
            409,
            'Payment is no longer settleable.'
        );
        $rate = PlatformSetting::commissionRate();
        $commission = round(((float) $payment->amount) * $rate / 100, 2);
        $techAmount = round((float) $payment->amount - $commission, 2);

        $payment->update([
            'status' => PaymentStatus::Successful->value,
            'commission_amount' => $commission,
            'technician_amount' => $techAmount,
            'paid_at' => now(),
        ]);

        $this->wallet->credit(
            $payment->technician_id, $techAmount, 'earning',
            Payment::class, $payment->id, "Earning for job #{$payment->job_id}"
        );
        $this->wallet->record(
            $payment->technician_id, -$commission, 'commission',
            Payment::class, $payment->id, "Platform commission {$rate}%"
        );

        event(new PaymentSuccessful($payment->fresh()));

        return $payment->fresh();
    }

    public function refund(User $admin, Payment $payment, string $reason): Payment
    {
        abort_unless($admin->isAdmin(), 403);
        abort_unless($payment->status === 'successful', 422, 'Only successful payments can be refunded.');

        return DB::transaction(function () use ($payment, $reason) {
            $locked = Payment::whereKey($payment->id)->lockForUpdate()->firstOrFail();
            abort_unless($locked->status === 'successful', 409, 'Payment is no longer refundable.');

            $this->gateway($locked->provider)->refund(
                (string) $locked->provider_transaction_id, (float) $locked->amount
            );

            $locked->update(['status' => PaymentStatus::Refunded->value]);
            $this->wallet->record(
                $locked->technician_id, -((float) $locked->technician_amount), 'refund',
                Payment::class, $locked->id, "Refund: {$reason}"
            );

            return $locked->fresh();
        });
    }
}

