<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\SubscriptionPlan;
use App\Models\PromoCode;
use App\Models\UserSubscription;
use App\Services\CinetPayService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class SubscriptionController extends Controller
{
    protected CinetPayService $cinetPayService;

    public function __construct(CinetPayService $cinetPayService)
    {
        $this->cinetPayService = $cinetPayService;
    }

    /**
     * Liste des forfaits d'abonnement disponibles (VIP & Montante)
     */
    public function plans()
    {
        $plans = SubscriptionPlan::where('is_active', true)->get()->map(function ($plan) {
            return [
                'id' => $plan->id,
                'code' => $plan->code,
                'name' => $plan->name,
                'price' => (int) $plan->price,
                'duration_days' => (int) $plan->duration_days,
                'duration_label' => $plan->code === 'MONTANTE' ? 'semaine' : 'mois',
                'description' => $plan->description,
                'features' => $plan->features_json ?: [],
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $plans,
        ]);
    }

    /**
     * Initialiser une souscription et générer le lien / token de paiement CinetPay
     */
    public function subscribe(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'plan_code' => 'required|string|exists:subscription_plans,code',
            'payment_method' => 'nullable|string|in:MOBILE_MONEY,CREDIT_CARD',
            'phone' => 'nullable|string',
            'promo_code' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation échouée',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $plan = SubscriptionPlan::where('code', $request->plan_code)->firstOrFail();
        $paymentMethod = $request->input('payment_method', 'MOBILE_MONEY');
        $promoCodeStr = $request->input('promo_code');

        $result = $this->cinetPayService->initiatePayment($user, $plan, $paymentMethod, $promoCodeStr);

        return response()->json($result);
    }

    /**
     * Mes abonnements et statut actuel
     */
    public function mySubscriptions(Request $request)
    {
        $user = $request->user();

        $activeSubscriptions = $user->activeSubscriptions()->with('plan')->get()->map(function ($sub) {
            return [
                'id' => $sub->id,
                'plan_code' => $sub->plan->code,
                'plan_name' => $sub->plan->name,
                'starts_at' => $sub->starts_at->toIso8601String(),
                'expires_at' => $sub->expires_at->toIso8601String(),
                'status' => $sub->status,
                'remaining_days' => max(0, Carbon::now()->diffInDays($sub->expires_at, false)),
            ];
        });

        return response()->json([
            'success' => true,
            'has_vip' => $user->hasActiveVip(),
            'has_montante' => $user->hasActiveMontante(),
            'free_trial_valid' => $user->hasFreeTrialCote5(),
            'free_trial_expires_at' => $user->free_trial_expires_at ? $user->free_trial_expires_at->toIso8601String() : null,
            'active_subscriptions' => $activeSubscriptions,
        ]);
    }

    /**
     * Vérifier la validité d'un code promo
     */
    public function checkPromoCode(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'code' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => 'Code manquant'], 400);
        }

        $promo = PromoCode::where('code', strtoupper($request->code))->first();

        if (!$promo || !$promo->isValid()) {
            return response()->json([
                'success' => false,
                'message' => 'Code promo invalide ou expiré.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'code' => $promo->code,
            'discount_percent' => $promo->discount_percent,
            'message' => "Code promo valide (-{$promo->discount_percent}% de réduction appliquée !)",
        ]);
    }
}
