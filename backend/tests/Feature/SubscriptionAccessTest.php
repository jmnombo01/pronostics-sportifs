<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Prediction;
use App\Models\SubscriptionPlan;
use App\Models\UserSubscription;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Carbon\Carbon;

class SubscriptionAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_free_trial_user_can_access_cote_5_but_is_locked_for_cote_10()
    {
        $user = User::factory()->create([
            'subscription_status' => 'FREE_TRIAL',
            'free_trial_expires_at' => Carbon::now()->addHours(24),
        ]);

        $predCote5 = Prediction::create([
            'title' => 'Match Côte 5',
            'competition' => 'Ligue 1',
            'country' => 'France',
            'championship' => 'Ligue 1',
            'match_date' => Carbon::today(),
            'match_time' => '20:00',
            'home_team' => 'PSG',
            'away_team' => 'Lyon',
            'type' => 'COTE_5',
            'odds' => 5.10,
            'confidence' => 5,
            'is_published' => true,
        ]);

        $predCote10 = Prediction::create([
            'title' => 'Match Côte 10',
            'competition' => 'Premier League',
            'country' => 'Angleterre',
            'championship' => 'Premier League',
            'match_date' => Carbon::today(),
            'match_time' => '20:00',
            'home_team' => 'City',
            'away_team' => 'Arsenal',
            'type' => 'COTE_10',
            'odds' => 10.50,
            'confidence' => 4,
            'is_published' => true,
        ]);

        $this->actingAs($user, 'sanctum');

        // Accès à la liste : Cote 5 n'est pas verrouillée, Cote 10 l'est
        $response = $this->getJson('/api/v1/predictions');
        $response->assertStatus(200);

        $data = $response->json('data');
        $cote5Item = collect($data)->firstWhere('id', $predCote5->id);
        $cote10Item = collect($data)->firstWhere('id', $predCote10->id);

        $this->assertFalse($cote5Item['is_locked']);
        $this->assertTrue($cote10Item['is_locked']);

        // Tentative d'accès au détail de Côte 10 verrouillé
        $detailResponse = $this->getJson('/api/v1/predictions/' . $predCote10->id);
        $detailResponse->assertStatus(403);
    }

    public function test_expired_user_without_subscription_is_locked_out()
    {
        $user = User::factory()->create([
            'subscription_status' => 'EXPIRED',
            'free_trial_expires_at' => Carbon::now()->subDays(1),
        ]);

        $predCote5 = Prediction::create([
            'title' => 'Match Côte 5',
            'competition' => 'Ligue 1',
            'country' => 'France',
            'championship' => 'Ligue 1',
            'match_date' => Carbon::today(),
            'match_time' => '20:00',
            'home_team' => 'PSG',
            'away_team' => 'Lyon',
            'type' => 'COTE_5',
            'odds' => 5.10,
            'confidence' => 5,
            'is_published' => true,
        ]);

        $this->actingAs($user, 'sanctum');

        $response = $this->getJson('/api/v1/predictions/' . $predCote5->id);
        $response->assertStatus(403)
                 ->assertJson(['code' => 'SUBSCRIPTION_REQUIRED']);
    }
}
