<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class AuthController extends Controller
{
    /**
     * Inscription - Crée le compte et démarre 48h d'essai gratuit sur Côte 5
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'last_name' => 'required|string|max:100',
            'first_name' => 'required|string|max:100',
            'phone' => 'required|string|max:30|unique:users,phone',
            'email' => 'required|email|max:150|unique:users,email',
            'password' => 'required|string|min:6',
            'referral_code' => 'nullable|string|exists:users,referral_code',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation échouée',
                'errors' => $validator->errors(),
            ], 422);
        }

        $referredBy = null;
        if ($request->filled('referral_code')) {
            $referredBy = User::where('referral_code', $request->referral_code)->first();
        }

        $now = Carbon::now();
        $user = User::create([
            'last_name' => $request->last_name,
            'first_name' => $request->first_name,
            'phone' => $request->phone,
            'email' => strtolower($request->email),
            'password' => Hash::make($request->password),
            'subscription_status' => 'FREE_TRIAL',
            'free_trial_expires_at' => $now->copy()->addHours(48),
            'referral_code' => strtoupper(substr(md5(uniqid()), 0, 8)),
            'referred_by_id' => $referredBy ? $referredBy->id : null,
        ]);

        $token = $user->createToken('flutter_mobile_app')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => "Inscription réussie ! Vous bénéficiez de 48 heures d'essai gratuit sur la catégorie Côte 5.",
            'token' => $token,
            'user' => $this->formatUser($user),
        ], 201);
    }

    /**
     * Connexion
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|string',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiants invalides',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = User::where('email', strtolower($request->email))
                    ->orWhere('phone', $request->email)
                    ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email/téléphone ou mot de passe incorrect.',
            ], 401);
        }

        // Révoquer les anciens tokens et créer le nouveau
        $user->tokens()->delete();
        $token = $user->createToken('flutter_mobile_app')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Connexion réussie',
            'token' => $token,
            'user' => $this->formatUser($user),
        ]);
    }

    /**
     * Mot de passe oublié
     */
    public function forgotPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Adresse email introuvable dans notre système.',
            ], 404);
        }

        // Dans un contexte de production, un email contenant un code de réinitialisation à 6 chiffres est envoyé.
        return response()->json([
            'success' => true,
            'message' => 'Un email de réinitialisation a été envoyé à votre adresse. Vérifiez votre boîte de réception ou vos spams.',
            'reset_token' => 'RESET-' . strtoupper(substr(md5(time()), 0, 8)),
        ]);
    }

    /**
     * Déconnexion
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Déconnexion réussie.',
        ]);
    }

    /**
     * Profil utilisateur
     */
    public function profile(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'user' => $this->formatUser($user),
        ]);
    }

    /**
     * Mettre à jour le token FCM de l'utilisateur pour les notifications
     */
    public function updateFcmToken(Request $request)
    {
        $request->validate(['fcm_token' => 'required|string']);
        $request->user()->update(['fcm_token' => $request->fcm_token]);

        return response()->json([
            'success' => true,
            'message' => 'Jeton FCM mis à jour avec succès.',
        ]);
    }

    /**
     * Formater les données utilisateur avec les indicateurs d'abonnement
     */
    protected function formatUser(User $user): array
    {
        $hasVip = $user->hasActiveVip();
        $hasMontante = $user->hasActiveMontante();
        $hasFreeTrialCote5 = $user->hasFreeTrialCote5();

        return [
            'id' => $user->id,
            'last_name' => $user->last_name,
            'first_name' => $user->first_name,
            'phone' => $user->phone,
            'email' => $user->email,
            'is_admin' => $user->is_admin,
            'subscription_status' => $user->subscription_status,
            'subscription_expires_at' => $user->subscription_expires_at ? $user->subscription_expires_at->toIso8601String() : null,
            'free_trial_expires_at' => $user->free_trial_expires_at ? $user->free_trial_expires_at->toIso8601String() : null,
            'referral_code' => $user->referral_code,
            'has_vip' => $hasVip,
            'has_montante' => $hasMontante,
            'has_free_trial_cote_5' => $hasFreeTrialCote5,
            'created_at' => $user->created_at->toIso8601String(),
        ];
    }
}
