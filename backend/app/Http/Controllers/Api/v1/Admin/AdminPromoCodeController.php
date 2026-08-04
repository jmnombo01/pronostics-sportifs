<?php

namespace App\Http\Controllers\Api\v1\Admin;

use App\Http\Controllers\Controller;
use App\Models\PromoCode;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class AdminPromoCodeController extends Controller
{
    /**
     * Liste des codes promo existants
     */
    public function index()
    {
        $promos = PromoCode::orderBy('created_at', 'desc')->get()->map(function ($p) {
            return [
                'id' => $p->id,
                'code' => $p->code,
                'discount_percent' => (int) $p->discount_percent,
                'max_uses' => (int) $p->max_uses,
                'used_count' => (int) $p->used_count,
                'expires_at' => $p->expires_at ? $p->expires_at->format('Y-m-d') : 'Sans expiration',
                'is_active' => $p->is_active,
                'is_valid' => $p->isValid(),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $promos,
        ]);
    }

    /**
     * Création d'un code promo
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'code' => 'required|string|max:30|unique:promo_codes,code',
            'discount_percent' => 'required|integer|min:1|max:100',
            'max_uses' => 'required|integer|min:1',
            'expires_at' => 'nullable|date',
            'is_active' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation échouée',
                'errors' => $validator->errors(),
            ], 422);
        }

        $promo = PromoCode::create([
            'code' => strtoupper(trim($request->code)),
            'discount_percent' => $request->discount_percent,
            'max_uses' => $request->max_uses,
            'used_count' => 0,
            'expires_at' => $request->expires_at,
            'is_active' => $request->input('is_active', true),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Code promo créé avec succès',
            'data' => $promo,
        ], 201);
    }

    /**
     * Modification d'un code promo
     */
    public function update(Request $request, $id)
    {
        $promo = PromoCode::findOrFail($id);
        $promo->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Code promo mis à jour',
            'data' => $promo,
        ]);
    }

    /**
     * Supprimer un code promo
     */
    public function destroy($id)
    {
        $promo = PromoCode::findOrFail($id);
        $promo->delete();

        return response()->json([
            'success' => true,
            'message' => 'Code promo supprimé',
        ]);
    }

    /**
     * Leaderboard et statistiques de parrainage
     */
    public function referralLeaderboard()
    {
        $topReferrers = User::withCount('referrals')
            ->having('referrals_count', '>', 0)
            ->orderBy('referrals_count', 'desc')
            ->limit(20)
            ->get()
            ->map(function ($u) {
                $activeReferrals = $u->referrals()->where('subscription_status', 'ACTIVE')->count();
                return [
                    'id' => $u->id,
                    'name' => "{$u->first_name} {$u->last_name}",
                    'phone' => $u->phone,
                    'email' => $u->email,
                    'referral_code' => $u->referral_code,
                    'total_referred' => (int) $u->referrals_count,
                    'active_referred' => (int) $activeReferrals,
                    'reward_days_earned' => (int) ($activeReferrals * 7),
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $topReferrers,
        ]);
    }
}
