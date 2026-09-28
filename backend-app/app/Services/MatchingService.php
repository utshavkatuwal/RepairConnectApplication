<?php

namespace App\Services;

use App\Models\ServiceRequest;
use App\Models\TechnicianProfile;
use Illuminate\Support\Collection;

class MatchingService
{
    public function __construct(private LocationService $geo) {}

    /**
     * Eligible technicians for a request: active + approved + specialty +
     * availability + within service radius. Ordered by distance. No
     * hardcoded selection — pure query + real coordinates.
     *
     * @return Collection<int, array{profile: TechnicianProfile, km: float}>
     */
    public function candidates(ServiceRequest $request, int $limit = 20): Collection
    {
        $profiles = TechnicianProfile::query()
            ->where('specialty_id', $request->specialty_id)
            ->where('verification_status', 'approved')
            ->whereIn('availability_status', ['online'])
            ->whereHas('user', fn ($q) => $q->where('status', 'active'))
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->with('user')
            ->get();

        return $profiles
            ->map(fn (TechnicianProfile $p) => [
                'profile' => $p,
                'km' => $this->geo->km(
                    (float) $request->latitude, (float) $request->longitude,
                    (float) $p->latitude, (float) $p->longitude,
                ),
            ])
            ->filter(fn (array $c) => $c['km'] <= (int) $c['profile']->service_radius)
            ->sortBy('km')
            ->take($limit)
            ->values();
    }
}
