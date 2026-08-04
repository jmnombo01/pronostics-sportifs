<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Carbon\Carbon;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_and_receive_48h_free_trial()
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'last_name' => 'Kaboré',
            'first_name' => 'Moussa',
            'phone' => '+22670112233',
            'email' => 'moussa@example.com',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertStatus(201)
                 ->assertJsonStructure([
                     'success',
                     'token',
                     'user' => [
                         'id',
                         'email',
                         'subscription_status',
                         'has_free_trial_cote_5',
                     ],
                 ]);

        $user = User::where('email', 'moussa@example.com')->first();
        $this->assertEquals('FREE_TRIAL', $user->subscription_status);
        $this->assertTrue($user->hasFreeTrialCote5());
    }

    public function test_user_can_login_successfully()
    {
        $user = User::factory()->create([
            'email' => 'login@example.com',
            'password' => bcrypt('Password123!'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'login@example.com',
            'password' => 'Password123!',
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure(['success', 'token', 'user']);
    }
}
