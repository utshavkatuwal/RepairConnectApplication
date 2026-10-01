<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Bill;
use App\Models\Job;
use Illuminate\Http\Request;

/**
 * Technician-issued bills for completed jobs. The technician creates the
 * bill; the customer pays exactly the issued amount (PaymentService
 * enforces the match, settlement marks the bill paid).
 */
class BillController extends Controller
{
    public function store(Request $request, int $jobId)
    {
        $job = Job::findOrFail($jobId);
        $user = $request->user();
        abort_unless($user->id === $job->technician_id, 403, 'Only the assigned technician can issue the bill.');
        abort_unless($job->status === 'completed', 422, 'Bill can only be issued after the job is completed.');

        $existing = Bill::where('job_id', $job->id)->where('status', Bill::STATUS_ISSUED)->first();
        abort_if($existing, 409, 'An issued bill already exists for this job.');

        $request->validate([
            'amount' => ['required', 'numeric', 'min:1', 'max:100000'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'line_items' => ['nullable', 'array', 'max:30'],
            'line_items.*.description' => ['required_with:line_items', 'string', 'max:200'],
            'line_items.*.amount' => ['required_with:line_items', 'numeric', 'min:0'],
        ]);

        $bill = Bill::create([
            'job_id' => $job->id,
            'technician_id' => $job->technician_id,
            'customer_id' => $job->customer_id,
            'amount' => (float) $request->input('amount'),
            'currency' => 'NPR',
            'line_items' => $request->input('line_items'),
            'notes' => $request->input('notes'),
            'status' => Bill::STATUS_ISSUED,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Bill issued. Customer can now pay.',
            'data' => $bill,
        ], 201);
    }

    /** Latest bill for a job (participants only; 404 when none). */
    public function show(Request $request, int $jobId)
    {
        $job = Job::findOrFail($jobId);
        abort_unless($job->involves($request->user()), 403);

        $bill = Bill::where('job_id', $job->id)->latest()->first();
        abort_unless($bill, 404, 'No bill for this job.');

        return response()->json(['success' => true, 'message' => 'Bill.', 'data' => $bill]);
    }
}
