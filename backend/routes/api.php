<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\v1\AuthController;
use App\Http\Controllers\Api\v1\PredictionController;
use App\Http\Controllers\Api\v1\SubscriptionController;
use App\Http\Controllers\Api\v1\CinetPayWebhookController;
use App\Http\Controllers\Api\v1\PayDunyaWebhookController;
use App\Http\Controllers\Api\v1\ReferralController;
use App\Http\Controllers\Api\v1\SupportController;
use App\Http\Controllers\Api\v1\Admin\AdminDashboardController;
use App\Http\Controllers\Api\v1\Admin\AdminPredictionController;
use App\Http\Controllers\Api\v1\Admin\AdminUserController;
use App\Http\Controllers\Api\v1\Admin\AdminAccountingController;
use App\Http\Controllers\Api\v1\Admin\AdminPromoCodeController;

/*
|--------------------------------------------------------------------------
| API Routes - Pronostics Sportifs (v1)
|--------------------------------------------------------------------------
| Authentification Sanctum + RBAC + Middlewares d'abonnement & d'essai gratuit
*/

Route::prefix('v1')->group(function () {

    // ---------------------------------------------------------------------
    // 1. Authentification & Inscription (Essai gratuit 48h Côte 5)
    // ---------------------------------------------------------------------
    Route::prefix('auth')->group(function () {
        Route::post('register', [AuthController::class, 'register']);
        Route::post('login', [AuthController::class, 'login']);
        Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
    });

    // ---------------------------------------------------------------------
    // 2. CinetPay Webhook & Retour (Public)
    // ---------------------------------------------------------------------
    Route::post('cinetpay/webhook', [CinetPayWebhookController::class, 'webhook']);
    Route::get('cinetpay/return', [CinetPayWebhookController::class, 'returnUrl']);

    // ---------------------------------------------------------------------
    // 2.bis PayDunya IPN Webhook, Retour & Annulation (Alternative/Fallback)
    // ---------------------------------------------------------------------
    Route::post('paydunya/ipn', [PayDunyaWebhookController::class, 'ipn']);
    Route::get('paydunya/return', [PayDunyaWebhookController::class, 'returnUrl']);
    Route::get('paydunya/cancel', [PayDunyaWebhookController::class, 'cancelUrl']);

    // ---------------------------------------------------------------------
    // 3. Plans d'Abonnement (Public)
    // ---------------------------------------------------------------------
    Route::get('subscriptions/plans', [SubscriptionController::class, 'plans']);

    // ---------------------------------------------------------------------
    // 4. Support, FAQ, WhatsApp, CGU & Confidentialité (Public)
    // ---------------------------------------------------------------------
    Route::prefix('support')->group(function () {
        Route::get('faqs', [SupportController::class, 'faqs']);
        Route::get('whatsapp', [SupportController::class, 'whatsapp']);
        Route::get('terms', [SupportController::class, 'terms']);
        Route::get('privacy', [SupportController::class, 'privacy']);
    });

    // =====================================================================
    // ROUTES PROTÉGÉES (SANCTUM AUTH)
    // =====================================================================
    Route::middleware('auth:sanctum')->group(function () {

        // Profil & Token FCM
        Route::get('auth/profile', [AuthController::class, 'profile']);
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::post('auth/fcm-token', [AuthController::class, 'updateFcmToken']);

        // Pronostics (avec vérification et masquage si l'abonnement est expiré)
        Route::get('predictions', [PredictionController::class, 'index']);
        Route::get('predictions/{id}', [PredictionController::class, 'show']);

        // Historique des pronostics, des paiements et des abonnements
        Route::prefix('history')->group(function () {
            Route::get('predictions', [PredictionController::class, 'history']);
            Route::get('payments', function (\Illuminate\Http\Request $request) {
                return response()->json([
                    'success' => true,
                    'data' => $request->user()->payments()->with('plan')->orderBy('created_at', 'desc')->get(),
                ]);
            });
            Route::get('subscriptions', function (\Illuminate\Http\Request $request) {
                return response()->json([
                    'success' => true,
                    'data' => $request->user()->subscriptions()->with('plan')->orderBy('created_at', 'desc')->get(),
                ]);
            });
        });

        // Souscription, paiement CinetPay et codes promo
        Route::prefix('subscriptions')->group(function () {
            Route::post('subscribe', [SubscriptionController::class, 'subscribe']);
            Route::get('my', [SubscriptionController::class, 'mySubscriptions']);
            Route::post('promo/check', [SubscriptionController::class, 'checkPromoCode']);
        });

        // Parrainage (Bonus)
        Route::get('referral/info', [ReferralController::class, 'info']);

        // =================================================================
        // ROUTES ADMINISTRATION (ACCÈS RÉSERVÉ AUX ADMINS - RBAC)
        // =================================================================
        Route::middleware('admin')->prefix('admin')->group(function () {

            // Statistiques globales du Dashboard
            Route::get('dashboard/stats', [AdminDashboardController::class, 'stats']);

            // Gestion complète des Pronostics (CRUD + Publish/Unpublish + Archiver)
            Route::get('predictions', [AdminPredictionController::class, 'index']);
            Route::post('predictions', [AdminPredictionController::class, 'store']);
            Route::put('predictions/{id}', [AdminPredictionController::class, 'update']);
            Route::delete('predictions/{id}', [AdminPredictionController::class, 'destroy']);

            Route::post('predictions/{id}/publish', [AdminPredictionController::class, 'publish']);
            Route::post('predictions/{id}/unpublish', [AdminPredictionController::class, 'unpublish']);
            Route::post('predictions/{id}/archive', [AdminPredictionController::class, 'archive']);

            // Gestion des utilisateurs et de leurs abonnements
            Route::get('users', [AdminUserController::class, 'index']);

            // Bilan comptable CinetPay (Rapport et Export CSV/Excel)
            Route::get('accounting/report', [AdminAccountingController::class, 'report']);
            Route::get('accounting/export', [AdminAccountingController::class, 'exportCsv']);

            // Gestion des Codes Promo & Parrainage
            Route::get('promo-codes', [AdminPromoCodeController::class, 'index']);
            Route::post('promo-codes', [AdminPromoCodeController::class, 'store']);
            Route::put('promo-codes/{id}', [AdminPromoCodeController::class, 'update']);
            Route::delete('promo-codes/{id}', [AdminPromoCodeController::class, 'destroy']);
            Route::get('referrals/leaderboard', [AdminPromoCodeController::class, 'referralLeaderboard']);
        });
    });
});
