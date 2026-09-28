<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class HealthController extends Controller
{
    public function __invoke()
    {
        $db = 'healthy';
        $redis = 'healthy';
        try {
            DB::select('select 1');
        } catch (\Throwable) {
            $db = 'unhealthy';
        }
        try {
            Cache::put('health', 1, 10);
        } catch (\Throwable) {
            $redis = 'unhealthy';
        }

        return response()->json([
            'success' => $db === 'healthy',
            'message' => 'Health.',
            'data' => ['api' => 'healthy', 'database' => $db, 'redis' => $redis],
        ], $db === 'healthy' ? 200 : 503);
    }
}
