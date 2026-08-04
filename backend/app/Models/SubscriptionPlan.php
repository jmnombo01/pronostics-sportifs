<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SubscriptionPlan extends Model
{
    use HasFactory;

    protected $fillable = [
        'code',
        'name',
        'price',
        'duration_days',
        'description',
        'features_json',
        'is_active',
    ];

    protected $casts = [
        'price' => 'integer',
        'duration_days' => 'integer',
        'features_json' => 'array',
        'is_active' => 'boolean',
    ];

    public function userSubscriptions()
    {
        return $this->hasMany(UserSubscription::class);
    }

    public function payments()
    {
        return $this->hasMany(Payment::class);
    }
}
