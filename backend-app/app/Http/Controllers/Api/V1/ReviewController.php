<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\ApiRequests\ReviewStoreRequest;
use App\Models\Complaint;
use App\Models\Job;
use App\Models\Review;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    /**
     * Scoped listing: by booking (participants + admin) or by
     * technician (public to authenticated users).
     */
    public function index(Request $request)
    {
        $request->validate([
            'booking_id' => ['nullable', 'integer'],
            'technician_id' => ['nullable', 'integer'],
        ]);
        $q = Review::query()->latest();
        if ($request->input('booking_id')) {
            $job = Job::findOrFail($request->integer('booking_id'));
            abort_unless(
                $job->involves($request->user()), 403,
                'Only job participants can view its reviews.'
            );
            $q->where('job_id', $job->id);
        }
        if ($request->input('technician_id')) {
            $q->where('technician_id', $request->integer('technician_id'));
        }
        $rows = $q->paginate(20);

        return response()->json([
            'success' => true, 'message' => 'Reviews.',
            'data' => $rows->items(),
            'meta' => ['total' => $rows->total()],
        ]);
    }

    public function store(ReviewStoreRequest $request)
    {
        $job = Job::findOrFail($request->integer('job_id'));
        abort_unless($request->user()->id === $job->customer_id, 403, 'Only the job customer can review.');
        abort_unless($job->status === 'completed', 422, 'Reviews unlock after completion.');
        abort_if(Review::where('job_id', $job->id)->exists(), 409, 'This job already has a review.');

        $review = Review::create([
            'job_id' => $job->id,
            'customer_id' => $request->user()->id,
            'technician_id' => $job->technician_id,
            'rating' => $request->integer('rating'),
            'comment' => $request->input('comment'),
        ]);

        return response()->json(['success' => true, 'message' => 'Review recorded.', 'data' => $review], 201);
    }

    public function update(Request $request, int $id)
    {
        $review = Review::findOrFail($id);
        abort_unless($request->user()->id === $review->customer_id, 403, 'Only the author can edit.');
        $request->validate([
            'rating' => ['sometimes', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:1000'],
        ]);
        $review->update($request->only(
            array_filter(['rating', 'comment'], fn ($k) => $request->has($k))
        ));

        return response()->json(['success' => true, 'message' => 'Review updated.', 'data' => $review->fresh()]);
    }

    public function destroy(Request $request, int $id)
    {
        $review = Review::findOrFail($id);
        abort_unless(
            $request->user()->id === $review->customer_id || $request->user()->isAdmin(),
            403, 'Only the author or an admin can delete.'
        );
        $review->delete();

        return response()->json(['success' => true, 'message' => 'Review deleted.', 'data' => []]);
    }

    public function report(Request $request, int $id)
    {
        $request->validate(['reason' => ['required', 'string', 'min:5']]);
        // Flagged for admin moderation (moderation queue reads complaints).
        Complaint::create([
            'reporter_id' => $request->user()->id,
            'body' => "Review #{$id} reported: ".$request->string('reason'),
        ]);

        return response()->json(['success' => true, 'message' => 'Reported for moderation.', 'data' => []]);
    }
}
