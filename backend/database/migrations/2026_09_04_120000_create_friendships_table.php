<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // One row per pair, owned by whoever asked first: `user_id` sent the
        // request and `friend_id` answers it. Keeping the direction is what
        // lets the app tell "waiting on them" from "waiting on you".
        Schema::create('friendships', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('friend_id')->constrained('users')->cascadeOnDelete();
            // pending | accepted
            $table->string('status')->default('pending');
            $table->timestamp('accepted_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'friend_id']);
            $table->index(['friend_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('friendships');
    }
};
