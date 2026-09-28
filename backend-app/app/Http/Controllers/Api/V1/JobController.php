<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;

use App\Events\JobCreated;
use App\Http\Requests\ApiRequests\JobTransitionRequest;
use App\Http\Requests\ApiRequests\ServiceRequestStoreRequest;
use App\Http\Resources\ApiResources\ServiceRequestResource;
use App\Models\Job;
use App\Models\ServiceRequest;
use App\Services\AcceptJobService;
use App\Services\JobLifecycleService;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Http\Request;

class JobController extends Controller
{
    use AuthorizesRequests;

    public function accept(Request $request, int $id, AcceptJobService $accept)
    {
        $serviceRequest = ServiceRequest::findOrFail($id);
        $job = $accept->accept($request->user(), $serviceRequest->id);
        $data = $job->toArray();
        $data['conversation_id'] = $job->conversation?->id;

        return response()->json([
            'success' => true, 'message' => 'Job accepted.',
            'data' => $data,
        ]);
    }

    public function transition(JobTransitionRequest $request, int $id, JobLifecycleService $jobs)
    {
        $job = Job::findOrFail($id);
        $updated = $jobs->transition($request->user(), $job, $request->string('status'), $request->input('reason'));

        return response()->json(['success' => true, 'message' => "Job {$updated->status}.", 'data' => $updated]);
    }

    public function show(Request $request, int $id)
    {
        $job = Job::with(['customer', 'technician', 'payments'])->findOrFail($id);
        $this->authorize('viewJob', $job);

        return response()->json([
            'success' => true, 'message' => 'Job.',
            'data' => new \App\Http\Resources\ApiResources\JobResource($job),
        ]);
    }

    public function mine(Request $request)
    {
        $u = $request->user();
        $rows = Job::where(fn ($q) => $q->where('customer_id', $u->id)->orWhere('technician_id', $u->id))
            ->latest()->paginate(20);

        return response()->json([
            'success' => true, 'message' => 'Jobs.',
            'data' => \App\Http\Resources\ApiResources\JobResource::collection($rows)->toArray($request),
            'meta' => ['total' => $rows->total()],
        ]);
    }
}
