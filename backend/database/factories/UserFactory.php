<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class UserFactory extends Factory
{
    protected $model = User::class;

    public function definition(): array
    {
        return [
            'last_name' => $this->faker->lastName(),
            'first_name' => $this->faker->firstName(),
            'phone' => '+22670' . $this->faker->unique()->randomNumber(6, true),
            'email' => $this->faker->unique()->safeEmail(),
            'password' => bcrypt('Password123!'),
            'is_admin' => false,
            'subscription_status' => 'FREE_TRIAL',
            'free_trial_expires_at' => now()->addHours(48),
            'referral_code' => strtoupper(Str::random(8)),
            'remember_token' => Str::random(10),
        ];
    }
}
