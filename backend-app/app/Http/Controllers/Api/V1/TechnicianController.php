<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\ApiRequests\TechnicianProfileRequest;
use App\Models\Job;
use App\Models\Review;
use App\Models\ServiceRequest;
use App\Models\Specialty;
use App\Models\TechnicianProfile;
use App\Services\LocationService;
use App\Services\MatchingService;
use App\Services\VerificationService;
use Illuminate\Http\Request;

class TechnicianController extends Controller
{
    /**
     * Public directory of eligible technicians: approved + active only.
     * Filters: q (name/specialty), category_id, available, lat/lng
     * (distance-sorted server-side). Paginated — never bulk.
     */
    public function search(Request $request, LocationService $geo)
    {
        $request->validate([
            'q' => ['nullable', 'string', 'max:120'],
            'category_id' => ['nullable', 'integer', 'exists:specialties,id'],
            'available' => ['nullable', 'boolean'],
            'lat' => ['nullable', 'numeric', 'between:-90,90'],
            'lng' => ['nullable', 'numeric', 'between:-180,180'],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);

        $profiles = TechnicianProfile::query()
            ->where('verification_status', 'approved')
            ->whereHas('user', fn ($q) => $q->where('status', 'active'))
            ->when($request->input('category_id'), fn ($q, $c) => $q->where('specialty_id', $c))
            ->when($request->boolean('available'), fn ($q) => $q->where('availability_status', 'online'))
            ->when($request->input('q'), function ($q, $term) {
                $q->where(fn ($w) => $w
                    ->whereHas('user', fn ($u) => $u->where('name', 'like', "%{$term}%"))
                    ->orWhereHas('specialty', fn ($s) => $s->where('name', 'like', "%{$term}%")));
            })
            ->with(['user:id,name', 'specialty:id,name'])
            ->get();

        $lat = $request->input('lat');
        $lng = $request->input('lng');
        $items = $profiles->map(fn ($p) => [
            'id' => $p->id,
            'user_id' => $p->user_id,
            'name' => $p->user?->name,
            'specialty' => $p->specialty?->name,
            'rating' => round((float) Review::where('technician_id', $p->user_id)->avg('rating'), 2),
            'jobs_completed' => $p->user
                ? Job::where('technician_id', $p->user_id)->where('status', 'completed')->count()
                : 0,
            'verified' => true,
            'available' => $p->availability_status === 'online',
            'avatar_url' => null,
            'service_area' => null,
            'km' => ($lat !== null && $lng !== null && $p->latitude && $p->longitude)
                ? round($geo->km((float) $lat, (float) $lng, (float) $p->latitude, (float) $p->longitude), 1)
                : null,
        ]);
        if ($lat !== null && $lng !== null) {
            $items = $items->sortBy('km')->values();
        }

        $perPage = (int) $request->input('per_page', 20);
        $page = (int) $request->input('page', 1);
        $total = $items->count();

        return response()->json([
            'success' => true,
            'message' => 'Technicians.',
            'data' => $items->forPage($page, $perPage)->values(),
            'meta' => ['page' => $page, 'per_page' => $perPage, 'total' => $total, 'last_page' => max(1, (int) ceil($total / $perPage))],
        ]);
    }

    public function storeProfile(TechnicianProfileRequest $request)
    {
        $profile = $request->user()->technicianProfile()->updateOrCreate(
            ['user_id' => $request->user()->id],
            $request->validated()
        );

        return response()->json([
            'success' => true,
            'message' => 'Technician profile saved. Verification pending.',
            'data' => $profile->fresh(),
        ]);
    }

    public function uploadDocument(Request $request, VerificationService $verification)
    {
        $request->validate([
            'document_type' => ['required', 'in:'.implode(',', VerificationService::TYPES)],
            'file' => ['required', 'file', 'max:10240'],
        ]);
        $profile = $request->user()->technicianProfile()->firstOrFail();
        $doc = $verification->storeDocument($profile, $request->file('file'), $request->string('document_type'));

        return response()->json([
            'success' => true,
            'message' => 'Document uploaded for review.',
            'data' => $doc,
        ], 201);
    }

    public function availability(Request $request)
    {
        $request->validate(['availability_status' => ['required', 'in:online,offline,busy']]);
        $request->user()->technicianProfile()->update([
            'availability_status' => $request->string('availability_status'),
        ]);

        return response()->json(['success' => true, 'message' => 'Availability updated.', 'data' => []]);
    }

    public function location(Request $request)
    {
        $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
        ]);
        $request->user()->technicianProfile()->update($request->only('latitude', 'longitude'));

        return response()->json(['success' => true, 'message' => 'Location updated.', 'data' => []]);
    }

    /** Own profile with live stats (rating avg, completed count). */
    public function show(Request $request)
    {
        $profile = $request->user()->technicianProfile()->with('specialty')->firstOrFail();
        $techId = $request->user()->id;

        return response()->json(['success' => true, 'message' => 'Technician profile.', 'data' => [
            'id' => $profile->id,
            'specialty' => $profile->specialty?->name,
            'specialty_id' => $profile->specialty_id,
            'bio' => $profile->bio,
            'experience_years' => $profile->experience_years,
            'service_radius' => $profile->service_radius,
            'availability_status' => $profile->availability_status,
            'verification_status' => $profile->verification_status,
            'rating' => round((float) \App\Models\Review::where('technician_id', $techId)->avg('rating'), 2),
            'jobs_completed' => \App\Models\Job::where('technician_id', $techId)->where('status', 'completed')->count(),
            'documents' => $profile->documents()->latest()->get(['id', 'document_type', 'status', 'rejection_reason', 'created_at']),
        ]]);
    }

    public function specialties()
    {
        return response()->json([
            'success' => true,
            'message' => 'Specialties.',
            'data' => Specialty::where('status', 'active')->orderBy('name')->get(),
        ]);
    }

    /** Eligible open requests near the technician (matching service). */
    public function nearbyRequests(Request $request, MatchingService $matching, LocationService $geo)
    {
        $profile = $request->user()->technicianProfile;
        abort_unless($profile?->isApproved(), 403, 'Technician is not approved.');
        abort_unless($profile->latitude && $profile->longitude, 422, 'Set your location first.');

        $open = ServiceRequest::whereIn('status', ['requested', 'searching'])
            ->where('specialty_id', $profile->specialty_id)
            ->paginate(20);

        $items = $open->getCollection()->map(function ($r) use ($profile, $geo) {
            return [
                'id' => $r->id,
                'title' => $r->title,
                'status' => $r->status,
                'km' => round($geo->km((float) $r->latitude, (float) $r->longitude, (float) $profile->latitude, (float) $profile->longitude), 1),
            ];
        })->filter(fn ($i) => $i['km'] <= (int) $profile->service_radius)->values();

        return response()->json([
            'success' => true,
            'message' => 'Nearby requests.',
            'data' => $items,
            'meta' => ['page' => $open->currentPage(), 'total' => $open->total()],
        ]);
    }
}
