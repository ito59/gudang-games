<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('username')->unique()->after('name');
            $table->text('bio')->nullable()->after('username');
            $table->string('location')->nullable()->after('bio');
            $table->string('avatar_path')->nullable()->after('location');
            $table->string('accent_color', 9)->default('#7C3AED')->after('avatar_path');

            // Denormalised counters shown on the profile screen.
            $table->unsignedInteger('games_owned')->default(0);
            $table->unsignedInteger('hours_played')->default(0);
            $table->unsignedInteger('achievements')->default(0);

            // What the member is playing right now; null means offline.
            $table->string('playing')->nullable();

            $table->boolean('is_admin')->default(false);
            $table->boolean('is_active')->default(true);
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'username',
                'bio',
                'location',
                'avatar_path',
                'accent_color',
                'games_owned',
                'hours_played',
                'achievements',
                'playing',
                'is_admin',
                'is_active',
            ]);
        });
    }
};
