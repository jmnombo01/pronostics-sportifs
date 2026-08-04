<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user || !$user->is_admin) {
            return response()->json([
                'success' => false,
                'code' => 'FORBIDDEN_ADMIN_ONLY',
                'message' => 'Accès refusé. Cette section est réservée aux administrateurs.',
            ], 403);
        }

        return $next($request);
    }
}
