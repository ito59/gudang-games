<?php

namespace App\Http\Controllers;

use App\Models\Game;
use App\Services\GameBundleExtractor;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

/**
 * Streams a game's trailer out of protected storage.
 *
 * `response()->file()` returns a BinaryFileResponse, which the kernel prepares
 * with Range support — without that a player cannot seek, and some clients
 * refuse to start at all.
 */
class TrailerController extends Controller
{
    public function __invoke(Request $request, Game $game): BinaryFileResponse
    {
        abort_unless($game->hasTrailer(), 404);

        // Drafts stay visible to administrators only.
        abort_unless($game->is_published || $request->user()?->is_admin, 404);

        $disk = Storage::disk(GameBundleExtractor::DISK);
        abort_unless($disk->exists($game->trailer_path), 404);

        return response()->file($disk->path($game->trailer_path), [
            'Content-Type' => $game->trailer_mime ?: 'video/mp4',
            'Accept-Ranges' => 'bytes',
            'Cache-Control' => 'private, max-age=3600',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }
}
