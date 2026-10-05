<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('games', function (Blueprint $table) {
            // How the game is delivered: a link out, or a bundle we host.
            $table->string('source_type', 8)->default('url')->after('slug');

            // source_type = url
            $table->string('game_url')->nullable()->after('source_type');

            // source_type = zip
            $table->string('bundle_path')->nullable()->after('game_url');
            $table->string('entry_path')->nullable()->after('bundle_path');
            $table->unsignedBigInteger('bundle_size')->nullable()->after('entry_path');
        });
    }

    public function down(): void
    {
        Schema::table('games', function (Blueprint $table) {
            $table->dropColumn([
                'source_type',
                'game_url',
                'bundle_path',
                'entry_path',
                'bundle_size',
            ]);
        });
    }
};
