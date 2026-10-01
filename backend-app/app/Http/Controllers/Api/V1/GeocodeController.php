<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\RateLimiter;

/**
 * Reverse geocoding server-side via OpenStreetMap Nominatim (free, no
 * key required; CARTO's geocoding API needs an org token the basemap
 * key does not grant). Failures return a null address honestly instead
 * of an invented one.
 */
class GeocodeController extends Controller
{
    public function reverse(Request $request)
    {
        $request->validate([
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
        ]);

        RateLimiter::hit('geocode:'.request()->ip(), 60);

        $address = null;

        try {
            $resp = Http::timeout(5)
                ->withHeaders(['User-Agent' => 'RepairConnect/1.0 (reverse-geocode)'])
                ->get('https://nominatim.openstreetmap.org/reverse', [
                    'format' => 'jsonv2',
                    'lat' => $request->input('lat'),
                    'lon' => $request->input('lng'),
                    'zoom' => 18,
                ]);
            if ($resp->successful()) {
                $address = $resp->json('display_name');
            }
        } catch (\Throwable $e) {
            report($e);
            $address = null;
        }

        return response()->json([
            'success' => true,
            'message' => 'Reverse geocode.',
            'data' => ['address' => $address, 'lat' => (float) $request->input('lat'), 'lng' => (float) $request->input('lng')],
        ]);
    }
}
