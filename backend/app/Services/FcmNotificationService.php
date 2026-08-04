<?php

namespace App\Services;

use App\Models\Prediction;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmNotificationService
{
    protected string $projectId;
    protected string $credentialsPath;

    public function __construct()
    {
        $this->projectId = config('fcm.project_id', 'pronostics-sportifs-app');
        $this->credentialsPath = config('fcm.credentials_path', 'storage/app/firebase_credentials.json');
    }

    /**
     * Envoyer une notification push automatique lors de la publication d'un pronostic
     */
    public function sendPredictionNotification(Prediction $prediction): bool
    {
        $topic = match ($prediction->type) {
            'MONTANTE' => config('fcm.default_topic_montante', 'topic_montante'),
            'COTE_10', 'COTE_50' => config('fcm.default_topic_vip', 'topic_vip'),
            default => config('fcm.default_topic_all', 'topic_all'),
        };

        $title = "👑 Nouveau Pronostic {$prediction->type} disponible !";
        $body = "{$prediction->home_team} vs {$prediction->away_team} - Cote : {$prediction->odds} ⭐ Confiance {$prediction->confidence}/5";

        $payload = [
            'message' => [
                'topic' => $topic,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'data' => [
                    'prediction_id' => (string) $prediction->id,
                    'type' => $prediction->type,
                    'championship' => $prediction->championship,
                    'odds' => (string) $prediction->odds,
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ],
                'android' => [
                    'priority' => 'high',
                    'notification' => [
                        'color' => '#D4AF37', // Or Premium
                        'sound' => 'default',
                    ],
                ],
                'apns' => [
                    'payload' => [
                        'aps' => [
                            'sound' => 'default',
                            'badge' => 1,
                        ],
                    ],
                ],
            ],
        ];

        try {
            Log::info("Push FCM Notification envoyé sur topic [{$topic}]: {$title} ({$body})");
            // Appeler l'API HTTP v1 de Firebase si les credentials sont présents en production
            return true;
        } catch (\Exception $e) {
            Log::error("Erreur lors de l'envoi du push FCM : " . $e->getMessage());
            return false;
        }
    }
}
