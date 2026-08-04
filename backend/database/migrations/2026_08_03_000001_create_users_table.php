<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('last_name', 100);
            $table->string('first_name', 100);
            $table->string('phone', 30)->unique();
            $table->string('email', 150)->unique();
            $table->string('password');
            $table->boolean('is_admin')->default(false);
            $table->enum('subscription_status', ['FREE_TRIAL', 'ACTIVE', 'EXPIRED', 'NONE'])->default('FREE_TRIAL');
            $table->timestamp('subscription_expires_at')->nullable();
            $table->timestamp('free_trial_expires_at')->nullable();
            $table->string('referral_code', 20)->nullable()->unique();
            $table->unsignedBigInteger('referred_by_id')->nullable();
            $table->string('fcm_token', 255)->nullable();
            $table->rememberToken();
            $table->timestamps();

            $table->foreign('referred_by_id')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
