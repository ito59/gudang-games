<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

/**
 * Bundles used to be extracted onto the `public` disk, which the web server
 * serves directly — anyone with the URL could pull the files, and an
 * unpublished game was readable too.
 *
 * This moves what is already on disk to the protected `local` disk and
 * rewrites `entry_path` to be relative to the bundle, which is what the play
 * route expects.
 */
return new class extends Migration
{
    public function up(): void
    {
        $public = Storage::disk('public');
        $local = Storage::disk('local');

        foreach (DB::table('games')->whereNotNull('bundle_path')->get() as $game) {
            $bundle = $game->bundle_path;

            foreach ($public->allFiles($bundle) as $file) {
                $stream = $public->readStream($file);
                if ($stream === null) {
                    continue;
                }
                $local->writeStream($file, $stream);
                if (is_resource($stream)) {
                    fclose($stream);
                }
            }

            $public->deleteDirectory($bundle);

            // "games/slug/index.html" -> "index.html"
            $entry = $game->entry_path;
            if (filled($entry) && str_starts_with($entry, $bundle.'/')) {
                DB::table('games')
                    ->where('id', $game->id)
                    ->update(['entry_path' => substr($entry, strlen($bundle) + 1)]);
            }
        }
    }

    public function down(): void
    {
        $public = Storage::disk('public');
        $local = Storage::disk('local');

        foreach (DB::table('games')->whereNotNull('bundle_path')->get() as $game) {
            $bundle = $game->bundle_path;

            foreach ($local->allFiles($bundle) as $file) {
                $stream = $local->readStream($file);
                if ($stream === null) {
                    continue;
                }
                $public->writeStream($file, $stream);
                if (is_resource($stream)) {
                    fclose($stream);
                }
            }

            $local->deleteDirectory($bundle);

            if (filled($game->entry_path) && ! str_starts_with($game->entry_path, $bundle.'/')) {
                DB::table('games')
                    ->where('id', $game->id)
                    ->update(['entry_path' => $bundle.'/'.$game->entry_path]);
            }
        }
    }
};
