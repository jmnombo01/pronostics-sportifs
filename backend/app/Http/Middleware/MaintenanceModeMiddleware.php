<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class MaintenanceModeMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        if (env('APP_MAINTENANCE_MODE', false)) {
            // Permettre l'accès aux administrateurs même en mode maintenance
            $user = $request->user();
            if (!$user || !$user->is_admin) {
                return response()->json([
                    'success' => false,
                    'code' => 'MAINTENANCE_MODE',
                    'message' => 'L\'application est actuellement en maintenance pour amélioration. Veuillez réessayer dans quelques instants.',
                ], 503);
            }
        }

        return $next($request);
    }
}
