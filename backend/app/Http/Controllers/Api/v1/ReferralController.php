<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ReferralController extends Controller
{
    /**
     * Obtenir les informations de parrainage de l'utilisateur
     */
    public function info(Request $request)
    {
        $user = $request->user();

        $referrals = $user->referrals()->select('id', 'first_name', 'last_name', 'created_at', 'subscription_status')->get()->map(function ($ref) {
            return [
                'id' => $ref->id,
                'name' => "{$ref->first_name} " . substr($ref->last_name, 0, 1) . ".",
                'status' => $ref->subscription_status,
                'joined_at' => $ref->created_at->format('Y-m-d'),
            ];
        });

        $activeReferralsCount = $user->referrals()->where('subscription_status', 'ACTIVE')->count();

        return response()->json([
            'success' => true,
            'referral_code' => $user->referral_code,
            'referral_url' => "https://pronostics-sportifs.pro/register?ref=" . $user->referral_code,
            'total_referrals' => $referrals->count(),
            'active_referrals' => $activeReferralsCount,
            'reward_description' => "Gagnez 7 jours d'abonnement VIP gratuits pour chaque filleul qui s'abonne à une offre VIP ou Montante !",
            'referrals' => $referrals,
        ]);
    }
}
