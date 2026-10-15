<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Featured events — hand-written carousel slides — are gone. The home
 * carousel now shows only games flagged `is_featured`.
 *
 * Rolling back restores the table's structure, not the slides it held.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::dropIfExists('featured_events');
    }

    public function down(): void
    {
        Schema::create('featured_events', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description');
            $table->string('season')->default('SEASON 1');
            $table->boolean('is_live')->default(false);
            $table->string('image_path')->nullable();
            $table->foreignId('game_id')->nullable()->constrained()->nullOnDelete();
            $table->boolean('is_published')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();
        });
    }
};
