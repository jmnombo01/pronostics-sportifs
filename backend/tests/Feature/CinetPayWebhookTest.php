<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\SubscriptionPlan;
use App\Models\Payment;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Carbon\Carbon;

class CinetPayWebhookTest extends TestCase
{
    use RefreshDatabase;

    public function test_cinetpay_webhook_activates_vip_subscription_idempotently()
    {
        $user = User::factory()->create();
        $plan = SubscriptionPlan::create([
            'code' => 'VIP',
            'name' => 'Abonnement VIP Mensuel',
            'price' => 2000,
            'duration_days' => 30,
        ]);

        $txId = 'CP-20260803-TEST123';
        $payment = Payment::create([
            'user_id' => $user->id,
            'subscription_plan_id' => $plan->id,
            'transaction_id' => $txId,
            'amount' => 2000,
            'currency' => 'XOF',
            'status' => 'PENDING',
        ]);

        $webhookPayload = [
            'cpm_trans_id' => $txId,
            'cpm_amount' => '2000',
            'cpm_currency' => 'XOF',
            'cpm_payment_method' => 'MOBILE_MONEY',
        ];

        // 1er appel Webhook
        $response1 = $this->postJson('/api/v1/cinetpay/webhook', $webhookPayload);
        $response1->assertStatus(200)->assertJson(['code' => '00']);

        $user->refresh();
        $this->assertEquals('ACTIVE', $user->subscription_status);
        $this->assertTrue($user->hasActiveVip());

        // 2e appel Webhook pour la même transaction (Idempotence)
        $response2 = $this->postJson('/api/v1/cinetpay/webhook', $webhookPayload);
        $response2->assertStatus(200);

        // Vérifier qu'un seul abonnement actif a été créé
        $this->assertEquals(1, $user->activeSubscriptions()->count());
    }
}
