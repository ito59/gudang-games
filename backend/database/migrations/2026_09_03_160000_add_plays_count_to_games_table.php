<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('games', function (Blueprint $table) {
            // Popularity: how many times the app has opened this game.
            $table->unsignedBigInteger('plays_count')->default(0)->after('rating');
            $table->index('plays_count');
        });
    }

    public function down(): void
    {
        Schema::table('games', function (Blueprint $table) {
            $table->dropIndex(['plays_count']);
            $table->dropColumn('plays_count');
        });
    }
};
