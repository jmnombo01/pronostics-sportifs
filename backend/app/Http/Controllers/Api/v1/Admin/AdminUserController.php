<?php

namespace App\Http\Controllers\Api\v1\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserSubscription;
use Illuminate\Http\Request;

class AdminUserController extends Controller
{
    /**
     * Liste des utilisateurs avec leur statut d'abonnement
     */
    public function index(Request $request)
    {
        $query = User::orderBy('created_at', 'desc');

        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(function ($q) use ($s) {
                $q->where('email', 'like', "%{$s}%")
                  ->orWhere('phone', 'like', "%{$s}%")
                  ->orWhere('last_name', 'like', "%{$s}%")
                  ->orWhere('first_name', 'like', "%{$s}%");
            });
        }

        $users = $query->limit(100)->get()->map(function ($user) {
            return [
                'id' => $user->id,
                'name' => "{$user->first_name} {$user->last_name}",
                'phone' => $user->phone,
                'email' => $user->email,
                'is_admin' => $user->is_admin,
                'subscription_status' => $user->subscription_status,
                'has_vip' => $user->hasActiveVip(),
                'has_montante' => $user->hasActiveMontante(),
                'has_free_trial_cote_5' => $user->hasFreeTrialCote5(),
                'created_at' => $user->created_at->format('Y-m-d H:i'),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $users,
        ]);
    }
}
