<?php

namespace App\Http\Controllers\Api\v1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Prediction;
use App\Services\FcmNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class AdminPredictionController extends Controller
{
    protected FcmNotificationService $fcmService;

    public function __construct(FcmNotificationService $fcmService)
    {
        $this->fcmService = $fcmService;
    }

    /**
     * Liste de tous les pronostics (publiés, brouillons, archivés)
     */
    public function index(Request $request)
    {
        $query = Prediction::orderBy('match_date', 'desc')->orderBy('match_time', 'desc');

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        return response()->json([
            'success' => true,
            'data' => $query->get(),
        ]);
    }

    /**
     * Création d'un pronostic + Envoi automatique d'une notification push si publié
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:200',
            'competition' => 'required|string|max:150',
            'country' => 'required|string|max:100',
            'championship' => 'required|string|max:150',
            'match_date' => 'required|date',
            'match_time' => 'required|string|max:10',
            'home_team' => 'required|string|max:150',
            'away_team' => 'required|string|max:150',
            'type' => 'required|in:MONTANTE,COTE_5,COTE_10,COTE_50',
            'odds' => 'required|numeric|min:1.01',
            'confidence' => 'required|integer|min:1|max:5',
            'analysis' => 'nullable|string',
            'image_url' => 'nullable|string',
            'is_published' => 'boolean',
            'scheduled_at' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation échouée',
                'errors' => $validator->errors(),
            ], 422);
        }

        $isPublished = $request->input('is_published', true);

        $prediction = Prediction::create([
            'title' => $request->title,
            'competition' => $request->competition,
            'country' => $request->country,
            'championship' => $request->championship,
            'match_date' => $request->match_date,
            'match_time' => $request->match_time,
            'home_team' => $request->home_team,
            'away_team' => $request->away_team,
            'type' => $request->type,
            'odds' => $request->odds,
            'confidence' => $request->confidence,
            'analysis' => $request->analysis,
            'status' => 'PENDING',
            'image_url' => $request->image_url,
            'is_published' => $isPublished,
            'scheduled_at' => $request->scheduled_at,
            'published_at' => $isPublished ? Carbon::now() : null,
        ]);

        if ($isPublished) {
            $this->fcmService->sendPredictionNotification($prediction);
        }

        return response()->json([
            'success' => true,
            'message' => 'Pronostic créé avec succès',
            'data' => $prediction,
        ], 201);
    }

    /**
     * Modification globale d'un pronostic
     */
    public function update(Request $request, $id)
    {
        $prediction = Prediction::findOrFail($id);
        $prediction->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Pronostic mis à jour',
            'data' => $prediction,
        ]);
    }

    /**
     * Publier un pronostic et déclencher la notification push Firebase (FCM)
     */
    public function publish($id)
    {
        $prediction = Prediction::findOrFail($id);

        $prediction->update([
            'is_published' => true,
            'published_at' => Carbon::now(),
        ]);

        $this->fcmService->sendPredictionNotification($prediction);

        return response()->json([
            'success' => true,
            'message' => 'Pronostic publié et notification push envoyée',
            'data' => $prediction,
        ]);
    }

    /**
     * Dépublier un pronostic
     */
    public function unpublish($id)
    {
        $prediction = Prediction::findOrFail($id);
        $prediction->update(['is_published' => false]);

        return response()->json([
            'success' => true,
            'message' => 'Pronostic dépublié',
            'data' => $prediction,
        ]);
    }

    /**
     * Archiver un pronostic
     */
    public function archive($id)
    {
        $prediction = Prediction::findOrFail($id);
        $prediction->update(['is_archived' => true, 'is_published' => false]);

        return response()->json([
            'success' => true,
            'message' => 'Pronostic archivé',
            'data' => $prediction,
        ]);
    }

    /**
     * Supprimer définitivement un pronostic
     */
    public function destroy($id)
    {
        $prediction = Prediction::findOrFail($id);
        $prediction->delete();

        return response()->json([
            'success' => true,
            'message' => 'Pronostic supprimé',
        ]);
    }
}
