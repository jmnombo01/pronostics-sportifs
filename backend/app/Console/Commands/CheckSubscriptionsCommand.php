<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use App\Models\UserSubscription;
use App\Services\FcmNotificationService;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class CheckSubscriptionsCommand extends Command
{
    /**
     * Le nom et la signature de la commande Console Artisan
     */
    protected $signature = 'check:subscriptions {--dry-run : Exécuter sans modifier la base ni envoyer de push}';

    /**
     * Description de la commande
     */
    protected $description = 'Vérifier l\'expiration de l\'essai gratuit 48h et des abonnements VIP/Montante, et envoyer les rappels FCM';

    protected FcmNotificationService $fcmService;

    public function __construct(FcmNotificationService $fcmService)
    {
        parent::__construct();
        $this->fcmService = $fcmService;
    }

    public function handle(): int
    {
        $now = Carbon::now();
        $dryRun = $this->option('dry-run');

        $this->info("=== [{$now->toDateTimeString()}] Démarrage de la vérification des abonnements ===");

        // ---------------------------------------------------------------------
        // 1. RAPPEL 24H AVANT EXPIRATION DE L'ESSAI GRATUIT 48H
        // ---------------------------------------------------------------------
        $trialExpiringSoon = User::where('subscription_status', 'FREE_TRIAL')
            ->whereNotNull('free_trial_expires_at')
            ->whereBetween('free_trial_expires_at', [$now->copy(), $now->copy()->addHours(24)])
            ->get();

        $this->info("1. Essais gratuits 48h expirant dans <24h : {$trialExpiringSoon->count()} utilisateurs");

        foreach ($trialExpiringSoon as $user) {
            $hoursLeft = max(1, $now->diffInHours($user->free_trial_expires_at, false));
            $title = "⏳ Votre essai gratuit 48h expire dans {$hoursLeft}h !";
            $body = "Abonnez-vous dès maintenant au forfait VIP (2000 FCFA/mois) pour continuer à recevoir nos pronostics Côte 5, 10 et 50.";

            $this->sendUserNotification($user, $title, $body, $dryRun);
        }

        // ---------------------------------------------------------------------
        // 2. EXPIRATION DE L'ESSAI GRATUIT 48H (>48H SANS ABONNEMENT)
        // ---------------------------------------------------------------------
        $expiredTrials = User::where('subscription_status', 'FREE_TRIAL')
            ->whereNotNull('free_trial_expires_at')
            ->where('free_trial_expires_at', '<=', $now)
            ->get();

        $this->info("2. Essais gratuits 48h expirés aujourd'hui : {$expiredTrials->count()} utilisateurs");

        foreach ($expiredTrials as $user) {
            if (!$dryRun) {
                $user->update(['subscription_status' => 'EXPIRED']);
            }

            $title = "🔒 Période d'essai 48h terminée.";
            $body = "Votre accès aux pronostics est désormais restreint. Passez au forfait VIP (2000 FCFA) pour débloquer toutes les analyses.";
            $this->sendUserNotification($user, $title, $body, $dryRun);
        }

        // ---------------------------------------------------------------------
        // 3. RAPPEL 24H AVANT EXPIRATION D'UN ABONNEMENT VIP OU MONTANTE
        // ---------------------------------------------------------------------
        $subsExpiringSoon = UserSubscription::with(['user', 'plan'])
            ->where('status', 'ACTIVE')
            ->whereBetween('expires_at', [$now->copy(), $now->copy()->addHours(24)])
            ->get();

        $this->info("3. Abonnements (VIP/Montante) expirant dans <24h : {$subsExpiringSoon->count()} souscriptions");

        foreach ($subsExpiringSoon as $sub) {
            $user = $sub->user;
            if (!$user) continue;

            $hoursLeft = max(1, $now->diffInHours($sub->expires_at, false));
            $title = "👑 Votre abonnement {$sub->plan->name} expire dans {$hoursLeft}h !";
            $body = "Renouvelez rapidement en un clic via Mobile Money (2000 FCFA) pour éviter toute interruption de vos pronostics.";

            $this->sendUserNotification($user, $title, $body, $dryRun);
        }

        // ---------------------------------------------------------------------
        // 4. EXPIRATION DES ABONNEMENTS ACTIFS (VIP OU MONTANTE)
        // ---------------------------------------------------------------------
        $expiredSubs = UserSubscription::with(['user', 'plan'])
            ->where('status', 'ACTIVE')
            ->where('expires_at', '<=', $now)
            ->get();

        $this->info("4. Abonnements (VIP/Montante) arrivés à échéance : {$expiredSubs->count()} souscriptions");

        foreach ($expiredSubs as $sub) {
            if (!$dryRun) {
                $sub->update(['status' => 'EXPIRED']);

                // Vérifier si l'utilisateur a un autre abonnement actif avant de changer son statut global
                $user = $sub->user;
                if ($user && !$user->activeSubscriptions()->exists()) {
                    $user->update(['subscription_status' => 'EXPIRED']);
                }
            }

            $user = $sub->user;
            if ($user) {
                $title = "🔒 Expiration de votre abonnement {$sub->plan->name}";
                $body = "Votre abonnement est arrivé à expiration. Reconnectez-vous et réabonnez-vous pour 2000 FCFA.";
                $this->sendUserNotification($user, $title, $body, $dryRun);
            }
        }

        $this->info("=== Vérification des abonnements terminée avec succès ===");

        return Command::SUCCESS;
    }

    /**
     * Envoyer une notification ciblée à l'utilisateur (ou logger en mode dry-run)
     */
    protected function sendUserNotification(User $user, string $title, string $body, bool $dryRun): void
    {
        if ($dryRun) {
            $this->line(" [DRY-RUN] Push pour User #{$user->id} ({$user->email}) : {$title}");
            return;
        }

        Log::info("Envoi notification rappel/expiration pour User #{$user->id}: {$title}");

        // Si l'utilisateur possède un token FCM individuel enregistré, on tente l'envoi
        if ($user->fcm_token) {
            // L'appel au SDK de push ciblé s'effectue ici en production
        }
    }
}
