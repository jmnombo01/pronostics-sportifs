<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Carbon\Carbon;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'last_name',
        'first_name',
        'phone',
        'email',
        'password',
        'is_admin',
        'subscription_status',
        'subscription_expires_at',
        'free_trial_expires_at',
        'referral_code',
        'referred_by_id',
        'fcm_token',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'is_admin' => 'boolean',
        'subscription_expires_at' => 'datetime',
        'free_trial_expires_at' => 'datetime',
    ];

    /**
     * Relations
     */
    public function subscriptions()
    {
        return $this->hasMany(UserSubscription::class);
    }

    public function activeSubscriptions()
    {
        return $this->subscriptions()
                    ->where('status', 'ACTIVE')
                    ->where('expires_at', '>', Carbon::now());
    }

    public function payments()
    {
        return $this->hasMany(Payment::class);
    }

    public function referrer()
    {
        return $this->belongsTo(User::class, 'referred_by_id');
    }

    public function referrals()
    {
        return $this->hasMany(User::class, 'referred_by_id');
    }

    /**
     * Accès VIP actif (Côte 5, Côte 10, Côte 50)
     */
    public function hasActiveVip(): bool
    {
        if ($this->is_admin) {
            return true;
        }

        return $this->activeSubscriptions()
                    ->whereHas('plan', function ($query) {
                        $query->where('code', 'VIP');
                    })->exists();
    }

    /**
     * Accès Montante actif (Montante uniquement)
     */
    public function hasActiveMontante(): bool
    {
        if ($this->is_admin) {
            return true;
        }

        return $this->activeSubscriptions()
                    ->whereHas('plan', function ($query) {
                        $query->where('code', 'MONTANTE');
                    })->exists();
    }

    /**
     * Essai gratuit de 48h actif pour Côte 5
     */
    public function hasFreeTrialCote5(): bool
    {
        if ($this->is_admin || $this->hasActiveVip()) {
            return true;
        }

        if ($this->free_trial_expires_at && Carbon::now()->lessThanOrEqualTo($this->free_trial_expires_at)) {
            return true;
        }

        return false;
    }

    /**
     * Détermine si l'utilisateur a accès à une catégorie de pronostic
     */
    public function canAccessPrediction(Prediction $prediction): bool
    {
        if ($this->is_admin) {
            return true;
        }

        // Le mode gratuit (Combiné de 3 matchs par jour) est accessible à tous à vie !
        if ($prediction->type === 'FREE_3_MATCHS' || $prediction->type === 'FREE') {
            return true;
        }

        return match ($prediction->type) {
            'COTE_5', 'COTE_10', 'COTE_50' => $this->hasActiveVip(),
            'MONTANTE' => $this->hasActiveMontante(),
            default => false,
        };
    }
}
