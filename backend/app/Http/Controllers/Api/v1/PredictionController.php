<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Prediction;
use Illuminate\Http\Request;

class PredictionController extends Controller
{
    /**
     * Récupérer la liste des pronostics en cours / publiés
     * - Gestion du verrouillage (is_locked) si l'utilisateur n'est pas abonné
     */
    public function index(Request $request)
    {
        $user = $request->user('sanctum');

        $query = Prediction::published()->orderBy('match_date', 'desc')->orderBy('match_time', 'asc');

        // Filtre par catégorie de pronostic
        if ($request->filled('type')) {
            $query->ofType($request->type);
        }

        // Recherche par championnat, équipe, date ou statut
        $query->search($request->only(['championship', 'team', 'match_date', 'status']));

        $predictions = $query->get()->map(function (Prediction $prediction) use ($user) {
            return $this->formatPrediction($prediction, $user);
        });

        return response()->json([
            'success' => true,
            'data' => $predictions,
        ]);
    }

    /**
     * Détail d'un pronostic
     */
    public function show($id, Request $request)
    {
        $user = $request->user('sanctum');
        $prediction = Prediction::published()->find($id);

        if (!$prediction) {
            return response()->json([
                'success' => false,
                'message' => 'Pronostic introuvable ou non publié.',
            ], 404);
        }

        $formatted = $this->formatPrediction($prediction, $user);

        if ($formatted['is_locked']) {
            return response()->json([
                'success' => false,
                'code' => 'SUBSCRIPTION_REQUIRED',
                'message' => '🔒 Accès réservé aux abonnés. Veuillez vous abonner pour accéder à l\'analyse et aux détails complets du pronostic.',
                'data' => $formatted,
            ], 403);
        }

        return response()->json([
            'success' => true,
            'data' => $formatted,
        ]);
    }

    /**
     * Historique des pronostics terminés (Gagné, Perdu, Remboursé)
     */
    public function history(Request $request)
    {
        $user = $request->user('sanctum');
        $query = Prediction::whereIn('status', ['WON', 'LOST', 'VOID'])
                           ->where('is_archived', false)
                           ->orderBy('match_date', 'desc');

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        $predictions = $query->limit(50)->get()->map(function (Prediction $prediction) use ($user) {
            return $this->formatPrediction($prediction, $user);
        });

        return response()->json([
            'success' => true,
            'data' => $predictions,
        ]);
    }

    /**
     * Formate un pronostic et applique la logique de verrouillage (is_locked)
     */
    protected function formatPrediction(Prediction $prediction, $user = null): array
    {
        $hasAccess = false;

        if ($user) {
            $hasAccess = $user->canAccessPrediction($prediction);
        }

        $isLocked = !$hasAccess;

        // Gestion des sélections (matchs du combiné Côte 5 / Côte 10 / Côte 50)
        $rawSelections = $prediction->selections_json ?: [];
        $formattedSelections = [];

        foreach ($rawSelections as $index => $sel) {
            $formattedSelections[] = [
                'index' => $index + 1,
                'match' => $sel['match'] ?? "Match #" . ($index + 1),
                'championship' => $sel['championship'] ?? $prediction->championship,
                'match_time' => $sel['match_time'] ?? $prediction->match_time,
                'tip' => $isLocked ? "🔒 Pari réservé aux abonnés" : ($sel['tip'] ?? "Victoire à Domicile (1)"),
                'odds' => $isLocked ? null : (float) ($sel['odds'] ?? 1.50),
                'status' => $sel['status'] ?? $prediction->status,
            ];
        }

        // Si le ticket n'a pas de sélections explicites en base, on en génère une par défaut à partir des équipes du ticket
        if (empty($formattedSelections)) {
            $formattedSelections[] = [
                'index' => 1,
                'match' => "{$prediction->home_team} vs {$prediction->away_team}",
                'championship' => $prediction->championship,
                'match_time' => $prediction->match_time,
                'tip' => $isLocked ? "🔒 Pari réservé aux abonnés" : "Victoire de {$prediction->home_team}",
                'odds' => $isLocked ? null : (float) $prediction->odds,
                'status' => $prediction->status,
            ];
        }

        return [
            'id' => $prediction->id,
            'title' => $prediction->title,
            'competition' => $prediction->competition,
            'country' => $prediction->country,
            'championship' => $prediction->championship,
            'match_date' => $prediction->match_date->format('Y-m-d'),
            'match_time' => $prediction->match_time,
            'home_team' => $prediction->home_team,
            'away_team' => $prediction->away_team,
            'type' => $prediction->type,
            'odds' => (float) $prediction->odds,
            'confidence' => (int) $prediction->confidence,
            'status' => $prediction->status,
            'image_url' => $prediction->image_url ?: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=600&q=80',
            'is_locked' => $isLocked,
            'selections' => $formattedSelections,
            'matches_count' => count($formattedSelections),
            'analysis' => $isLocked ? '🔒 Contenu réservé aux abonnés. Abonnez-vous pour consulter notre analyse complète, les pronostics détaillés de chaque match du combiné et nos conseils de mise.' : ($prediction->analysis ?: 'Analyse d\'expert : combiné très favorable en fonction des statistiques des 5 dernières rencontres.'),
            'created_at' => $prediction->created_at->toIso8601String(),
        ];
    }
}
