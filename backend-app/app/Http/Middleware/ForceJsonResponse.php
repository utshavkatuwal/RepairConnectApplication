<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * API clients (curl, scripts) don't always send Accept headers.
 * Force JSON so auth failures render 401 JSON instead of crashing
 * on the missing web `login` route. Real clients already send it.
 */
class ForceJsonResponse
{
    public function handle(Request $request, Closure $next): Response
    {
        $request->headers->set('Accept', 'application/json');

        return $next($request);
    }
}
