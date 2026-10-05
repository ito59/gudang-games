<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('games', function (Blueprint $table) {
            // Trailer video, uploaded on its own page because the files are
            // large enough that failing mid-upload should not cost an admin
            // the rest of their edits.
            $table->string('trailer_path')->nullable()->after('bundle_size');
            $table->string('trailer_mime', 100)->nullable()->after('trailer_path');
            $table->unsignedBigInteger('trailer_size')->nullable()->after('trailer_mime');
        });
    }

    public function down(): void
    {
        Schema::table('games', function (Blueprint $table) {
            $table->dropColumn(['trailer_path', 'trailer_mime', 'trailer_size']);
        });
    }
};
