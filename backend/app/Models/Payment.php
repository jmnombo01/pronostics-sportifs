<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'subscription_plan_id',
        'transaction_id',
        'cinetpay_token',
        'amount',
        'currency',
        'status',
        'payment_method',
        'operator_id',
        'raw_response',
        'paid_at',
    ];

    protected $casts = [
        'amount' => 'integer',
        'raw_response' => 'array',
        'paid_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function plan()
    {
        return $this->belongsTo(SubscriptionPlan::class, 'subscription_plan_id');
    }
}
