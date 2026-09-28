<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureRole
{
    /**
     * Roles are read from the authenticated backend user — never from
     * client input.
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();
        if (! $user || ! $user->isRole(...$roles)) {
            return response()->json([
                'success' => false,
                'message' => 'Forbidden for your role.',
            ], 403);
        }

        return $next($request);
    }
}
