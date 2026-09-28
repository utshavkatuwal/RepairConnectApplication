<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\TechnicianProfile;
use App\Services\VerificationService;
use Illuminate\Http\Request;

class VerificationController extends Controller
{
    public function queue(Request $request)
    {
        $q = TechnicianProfile::with(['user', 'specialty'])
            ->where('verification_status', $request->input('status', 'pending'))
            ->paginate(20);

        return response()->json(['success' => true, 'message' => 'Verification queue.', 'data' => $q->items(), 'meta' => ['total' => $q->total()]]);
    }

    public function approve(Request $request, int $id, VerificationService $verification)
    {
        $profile = TechnicianProfile::findOrFail($id);
        $verification->approve($request->user(), $profile);

        return response()->json(['success' => true, 'message' => 'Technician approved.', 'data' => []]);
    }

    public function reject(Request $request, int $id, VerificationService $verification)
    {
        $request->validate(['reason' => ['required', 'string', 'min:5']]);
        $profile = TechnicianProfile::findOrFail($id);
        $verification->reject($request->user(), $profile, $request->string('reason'));

        return response()->json(['success' => true, 'message' => 'Technician rejected.', 'data' => []]);
    }

    public function resubmit(Request $request, int $id, VerificationService $verification)
    {
        $request->validate(['reason' => ['required', 'string', 'min:5']]);
        $profile = TechnicianProfile::findOrFail($id);
        $verification->requestResubmission($request->user(), $profile, $request->string('reason'));

        return response()->json(['success' => true, 'message' => 'Correction requested.', 'data' => []]);
    }
}
