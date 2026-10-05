<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            // "<lower id>:<higher id>" for a one-to-one thread, so the database
            // itself guarantees a pair never ends up with two threads. A group
            // conversation would leave this null and lean on the pivot alone.
            $table->string('pair_key')->nullable()->unique();
            // Denormalised so the conversation list can be ordered without
            // touching every thread's messages.
            $table->timestamp('last_message_at')->nullable();
            $table->timestamps();

            $table->index('last_message_at');
        });

        Schema::create('conversation_user', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            // The last message this member has seen. An id rather than a
            // timestamp: a message sent in the same second as the read would
            // be silently swallowed by a `created_at >` comparison.
            $table->unsignedBigInteger('last_read_message_id')->nullable();
            $table->timestamps();

            $table->unique(['conversation_id', 'user_id']);
            $table->index(['user_id', 'conversation_id']);
        });

        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->text('body');
            $table->timestamps();

            $table->index(['conversation_id', 'id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('messages');
        Schema::dropIfExists('conversation_user');
        Schema::dropIfExists('conversations');
    }
};
