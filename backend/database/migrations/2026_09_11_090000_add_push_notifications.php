<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // On by default: somebody who installs a chat app expects to be
            // told when they are written to. Turning it off is a choice they
            // make, not one they have to find.
            $table->boolean('notify_chat')->default(true)->after('is_active');
            $table->boolean('notify_news')->default(true)->after('notify_chat');
        });

        // One row per install, not per member: the same person on a phone and
        // a tablet has to be reached on both, and signing out on one must not
        // silence the other.
        Schema::create('device_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            // FCM registration tokens are long and change on reinstall.
            $table->string('token', 512);
            $table->string('platform', 16)->nullable();
            $table->timestamp('used_at')->nullable();
            $table->timestamps();

            // Hashed, because the token itself is longer than an index key.
            $table->string('token_hash', 64)->unique();
            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('device_tokens');

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['notify_chat', 'notify_news']);
        });
    }
};
