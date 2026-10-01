<?php

namespace App\Http\Controllers\Api\V1;

use App\Events\JobCreated;
use App\Http\Controllers\Controller;
use App\Http\Requests\ApiRequests\ServiceRequestStoreRequest;
use App\Http\Resources\ApiResources\ServiceRequestResource;
use App\Models\ServiceRequest;
use App\Services\JobLifecycleService;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Http\Request;

class ServiceRequestController extends Controller
{
    use AuthorizesRequests;

    public function store(ServiceRequestStoreRequest $request)
    {
        // Never auto-assign: request persists as requested/searching
        // until an eligible technician explicitly accepts (§14).
        $req = ServiceRequest::create([
            ...$request->validated(),
            'customer_id' => $request->user()->id,
            'status' => 'requested',
        ]);
        event(new JobCreated($req));

        return response()->json([
            'success' => true,
            'message' => 'Request created. Searching for technicians.',
            'data' => new ServiceRequestResource($req),
        ], 201);
    }

    public function index(Request $request)
    {
        $rows = ServiceRequest::with('job')
            ->where('customer_id', $request->user()->id)
            ->latest()->paginate(20);

        return response()->json([
            'success' => true, 'message' => 'Requests.',
            'data' => ServiceRequestResource::collection($rows)->toArray($request),
            'meta' => ['total' => $rows->total(), 'page' => $rows->currentPage()],
        ]);
    }

    public function show(Request $request, int $id)
    {
        $row = ServiceRequest::findOrFail($id);
        $this->authorize('viewRequest', $row);

        return response()->json([
            'success' => true, 'message' => 'Request.',
            'data' => new ServiceRequestResource($row->load('job')),
        ]);
    }

    public function cancel(Request $request, int $id, JobLifecycleService $jobs)
    {
        $row = ServiceRequest::findOrFail($id);
        $this->authorize('viewRequest', $row);
        abort_unless($row->isOpen() && ! $row->job, 409, 'Request can no longer be cancelled directly.');

        $request->validate(['reason' => ['nullable', 'string', 'min:5']]);
        $row->update(['status' => 'cancelled']);

        return response()->json(['success' => true, 'message' => 'Request cancelled.', 'data' => []]);
    }
}
