<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use App\Models\Prediction;
use Carbon\Carbon;

class CheckSubscriptionAccess
{
    /**
     * Gérer l'accès aux pronostics selon la catégorie, l'abonnement en cours et l'essai gratuit (48 heures pour Côte 5)
     */
    public function handle(Request $request, Closure $next, string $category = null): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'code' => 'AUTH_REQUIRED',
                'message' => 'Authentification requise pour accéder à cette ressource.',
            ], 401);
        }

        if ($user->is_admin) {
            return $next($request);
        }

        // Si une catégorie est précisée (ou passée en query param)
        $targetCategory = $category ?: $request->query('type');

        if (!$targetCategory && $request->route('id')) {
            $pred = Prediction::find($request->route('id'));
            $targetCategory = $pred ? $pred->type : null;
        }

        if (!$targetCategory) {
            return $next($request);
        }

        // 1. COTE 5 -> Autorisé si abonnement VIP OU pendant les premières 48 heures (essai gratuit)
        if ($targetCategory === 'COTE_5') {
            if ($user->hasActiveVip() || $user->hasFreeTrialCote5()) {
                return $next($request);
            }
            return response()->json([
                'success' => false,
                'code' => 'SUBSCRIPTION_REQUIRED',
                'category' => 'COTE_5',
                'message' => "🔒 Votre période d'essai gratuit de 48h est expirée. Abonnez-vous au forfait VIP (2000 FCFA/mois) pour continuer à recevoir nos pronostics Côte 5, 10 et 50.",
            ], 403);
        }

        // 2. COTE 10 ou COTE 50 -> Forfait VIP requis
        if (in_array($targetCategory, ['COTE_10', 'COTE_50'])) {
            if ($user->hasActiveVip()) {
                return $next($request);
            }
            return response()->json([
                'success' => false,
                'code' => 'VIP_REQUIRED',
                'category' => $targetCategory,
                'message' => "🔒 Cette catégorie est strictement réservée aux abonnés VIP (2000 FCFA/mois).",
            ], 403);
        }

        // 3. MONTANTE -> Forfait Montante requis (2000 FCFA/semaine)
        if ($targetCategory === 'MONTANTE') {
            if ($user->hasActiveMontante()) {
                return $next($request);
            }
            return response()->json([
                'success' => false,
                'code' => 'MONTANTE_REQUIRED',
                'category' => 'MONTANTE',
                'message' => "🔒 Les pronostics Montante nécessitent l'abonnement Montante (2000 FCFA/semaine).",
            ], 403);
        }

        return $next($request);
    }
}
