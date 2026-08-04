<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('subscription_plan_id')->constrained('subscription_plans')->restrictOnDelete();
            $table->string('transaction_id', 100)->unique();
            $table->string('cinetpay_token', 255)->nullable();
            $table->unsignedInteger('amount');
            $table->string('currency', 10)->default('XOF');
            $table->enum('status', ['PENDING', 'ACCEPTED', 'FAILED', 'REFUNDED'])->default('PENDING');
            $table->string('payment_method', 50)->default('MOBILE_MONEY');
            $table->string('operator_id', 100)->nullable();
            $table->json('raw_response')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
