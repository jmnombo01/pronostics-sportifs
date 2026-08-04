<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('predictions', function (Blueprint $table) {
            $table->id();
            $table->string('title', 200);
            $table->string('competition', 150);
            $table->string('country', 100);
            $table->string('championship', 150);
            $table->date('match_date');
            $table->string('match_time', 10);
            $table->string('home_team', 150);
            $table->string('away_team', 150);
            $table->enum('type', ['MONTANTE', 'COTE_5', 'COTE_10', 'COTE_50']);
            $table->decimal('odds', 6, 2);
            $table->json('selections_json')->nullable()->comment('Liste des matchs du combiné');
            $table->unsignedTinyInteger('confidence')->default(4);
            $table->text('analysis')->nullable();
            $table->enum('status', ['PENDING', 'WON', 'LOST', 'VOID'])->default('PENDING');
            $table->string('image_url', 255)->nullable();
            $table->boolean('is_published')->default(true);
            $table->boolean('is_archived')->default(false);
            $table->timestamp('scheduled_at')->nullable();
            $table->timestamp('published_at')->nullable();
            $table->timestamps();

            $table->index('type');
            $table->index('status');
            $table->index('match_date');
            $table->index('championship');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('predictions');
    }
};
