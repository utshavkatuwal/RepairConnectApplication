<?php

namespace App\Http\Controllers\Api\V1;

use App\Events\WithdrawalRequested;
use App\Http\Controllers\Controller;
use App\Http\Requests\ApiRequests\WithdrawalRequestRequest;
use App\Models\WalletTransaction;
use App\Models\WithdrawalRequest;
use App\Services\Payments\WalletService;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function balance(Request $request, WalletService $wallet)
    {
        return response()->json(['success' => true, 'message' => 'Balance.', 'data' => [
            'balance' => $wallet->balance($request->user()->id),
        ]]);
    }

    public function ledger(Request $request)
    {
        $rows = WalletTransaction::where('technician_id', $request->user()->id)
            ->latest()->paginate(20);

        return response()->json(['success' => true, 'message' => 'Ledger.', 'data' => $rows->items(), 'meta' => ['total' => $rows->total()]]);
    }

    public function withdraw(WithdrawalRequestRequest $request, WalletService $wallet)
    {
        $w = $wallet->requestWithdrawal(
            $request->user(),
            (float) $request->input('amount'),
            $request->string('method'),
            $request->string('account_identifier')
        );
        event(new WithdrawalRequested($w));

        return response()->json(['success' => true, 'message' => 'Withdrawal requested.', 'data' => $w], 201);
    }

    public function decide(Request $request, int $id, WalletService $wallet)
    {
        $request->validate([
            'decision' => ['required', 'in:approved,processing,paid,rejected'],
            'note' => ['nullable', 'string', 'max:191'],
        ]);
        $w = WithdrawalRequest::findOrFail($id);
        $updated = $wallet->decideWithdrawal($request->user(), $w, $request->string('decision'), $request->input('note'));

        return response()->json(['success' => true, 'message' => "Withdrawal {$updated->status}.", 'data' => $updated]);
    }
}
