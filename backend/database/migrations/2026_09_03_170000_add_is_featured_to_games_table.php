<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('games', function (Blueprint $table) {
            // Promotes the game to the app's home carousel.
            $table->boolean('is_featured')->default(false)->after('is_published');
            $table->index(['is_featured', 'is_published']);
        });
    }

    public function down(): void
    {
        Schema::table('games', function (Blueprint $table) {
            $table->dropIndex(['is_featured', 'is_published']);
            $table->dropColumn('is_featured');
        });
    }
};
