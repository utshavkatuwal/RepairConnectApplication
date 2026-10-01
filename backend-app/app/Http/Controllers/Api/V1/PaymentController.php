<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\ApiRequests\PaymentInitiateRequest;
use App\Models\Job;
use App\Models\Payment;
use App\Services\Payments\PaymentService;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    use AuthorizesRequests;

    public function initiate(PaymentInitiateRequest $request, PaymentService $payments)
    {
        $job = Job::findOrFail($request->integer('job_id'));
        abort_unless($request->user()->id === $job->customer_id, 403);

        $payment = $payments->initiate(
            $request->user(), $job,
            $request->string('provider'),
            (float) $request->input('amount'),
            $request->string('idempotency_key')
        );

        return response()->json(['success' => true, 'message' => 'Payment initiated.', 'data' => $payment], 201);
    }

    /** Provider webhook. Validates signature via gateway verify(); never trusts flags. */
    public function webhook(string $provider, Request $request, PaymentService $payments)
    {
        $payment = $payments->handleCallback($provider, $request->all());

        return response()->json(['success' => true, 'message' => 'Callback processed.', 'data' => ['status' => $payment->status]]);
    }

    /** Sandbox confirmation (local dev provider). Verification shared with webhook path. */
    public function confirm(Request $request, int $id, PaymentService $payments)
    {
        $payment = Payment::findOrFail($id);
        $updated = $payments->confirm($request->user(), $payment);

        return response()->json(['success' => true, 'message' => 'Payment confirmed.', 'data' => $updated]);
    }

    public function show(Request $request, int $id)
    {
        $payment = Payment::findOrFail($id);
        $this->authorize('viewPayment', $payment);

        return response()->json(['success' => true, 'message' => 'Payment.', 'data' => $payment]);
    }

    public function refund(Request $request, int $id, PaymentService $payments)
    {
        $request->validate(['reason' => ['required', 'string', 'min:5']]);
        $payment = Payment::findOrFail($id);
        $updated = $payments->refund($request->user(), $payment, $request->string('reason'));

        return response()->json(['success' => true, 'message' => 'Payment refunded.', 'data' => $updated]);
    }

    /** All payment attempts for a job the caller participates in. */
    public function forJob(Request $request, int $id)
    {
        $job = Job::findOrFail($id);
        $this->authorize('viewJob', $job);
        $rows = Payment::where('job_id', $job->id)->latest()->get();

        return response()->json(['success' => true, 'message' => 'Job payments.', 'data' => $rows]);
    }

    /**
     * Invoice synthesized from the latest successful payment.
     * 404 until money has verifiably moved — never an invented total.
     */
    public function invoice(Request $request, int $id)
    {
        $job = Job::findOrFail($id);
        $this->authorize('viewJob', $job);
        $payment = Payment::where('job_id', $job->id)
            ->where('status', 'successful')
            ->latest()
            ->first();
        abort_unless($payment, 404, 'No invoice yet.');

        return response()->json(['success' => true, 'message' => 'Invoice.', 'data' => [
            'id' => "inv-{$job->id}-{$payment->id}",
            'booking_id' => $job->id,
            'total' => (float) $payment->amount,
            'issued_at' => $payment->paid_at,
        ]]);
    }
}
