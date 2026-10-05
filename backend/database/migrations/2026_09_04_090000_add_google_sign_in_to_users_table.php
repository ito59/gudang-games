<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Google's `sub` claim: stable for the account even if the person
            // later changes the email address on it, so it is what we key on.
            $table->string('google_id')->nullable()->unique()->after('email');
            $table->string('google_avatar_url')->nullable()->after('avatar_path');

            // Somebody who only ever signs in with Google has no password to
            // store, and a placeholder hash would be a password nobody chose.
            $table->string('password')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['google_id']);
            $table->dropColumn(['google_id', 'google_avatar_url']);
        });

        // Rows without a password cannot satisfy a NOT NULL column.
        DB::table('users')->whereNull('password')->update(['password' => '']);

        Schema::table('users', function (Blueprint $table) {
            $table->string('password')->nullable(false)->change();
        });
    }
};
