<?php

namespace App\Http\Controllers\Api\v1\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserSubscription;
use App\Models\Payment;
use App\Models\Prediction;
use Carbon\Carbon;

class AdminDashboardController extends Controller
{
    /**
     * Statistiques du Tableau de Bord Administrateur
     */
    public function stats()
    {
        $today = Carbon::today();
        $startOfMonth = Carbon::now()->startOfMonth();

        $totalUsers = User::count();
        $newUsersToday = User::whereDate('created_at', $today)->count();

        // Abonnés VIP et Montante actifs
        $vipSubscribers = UserSubscription::where('status', 'ACTIVE')
            ->where('expires_at', '>', Carbon::now())
            ->whereHas('plan', function ($q) {
                $q->where('code', 'VIP');
            })->distinct('user_id')->count('user_id');

        $montanteSubscribers = UserSubscription::where('status', 'ACTIVE')
            ->where('expires_at', '>', Carbon::now())
            ->whereHas('plan', function ($q) {
                $q->where('code', 'MONTANTE');
            })->distinct('user_id')->count('user_id');

        // Paiements du jour et du mois
        $paymentsTodayCount = Payment::where('status', 'ACCEPTED')
            ->whereDate('paid_at', $today)->count();
        $paymentsTodayAmount = Payment::where('status', 'ACCEPTED')
            ->whereDate('paid_at', $today)->sum('amount');

        $paymentsMonthCount = Payment::where('status', 'ACCEPTED')
            ->where('paid_at', '>=', $startOfMonth)->count();
        $paymentsMonthAmount = Payment::where('status', 'ACCEPTED')
            ->where('paid_at', '>=', $startOfMonth)->sum('amount');

        $totalRevenue = Payment::where('status', 'ACCEPTED')->sum('amount');

        $publishedPredictions = Prediction::where('is_published', true)
            ->where('is_archived', false)
            ->count();

        return response()->json([
            'success' => true,
            'stats' => [
                'total_users' => $totalUsers,
                'new_users_today' => $newUsersToday,
                'vip_subscribers' => $vipSubscribers,
                'montante_subscribers' => $montanteSubscribers,
                'payments_today' => [
                    'count' => (int) $paymentsTodayCount,
                    'amount_fcfa' => (int) $paymentsTodayAmount,
                ],
                'payments_month' => [
                    'count' => (int) $paymentsMonthCount,
                    'amount_fcfa' => (int) $paymentsMonthAmount,
                ],
                'total_revenue_fcfa' => (int) $totalRevenue,
                'published_predictions' => (int) $publishedPredictions,
            ],
        ]);
    }
}
