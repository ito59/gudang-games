<?php

namespace App\Http\Controllers;

use App\Models\Game;
use App\Services\GameBundleExtractor;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

/**
 * Streams a hosted game out of protected storage.
 *
 * Bundles are not in a web-served directory, so every byte goes through here.
 * That is the point: it lets the app decide who may load a game, and nothing
 * inside a bundle is ever executed — it is only read and sent.
 */
class GamePlayController extends Controller
{
    /**
     * Content types for what game bundles actually contain. Guessing from the
     * file itself gets JavaScript wrong (text/plain), and a wrong type breaks
     * module scripts and WebAssembly streaming compilation.
     */
    private const MIME_TYPES = [
        'html' => 'text/html',
        'htm' => 'text/html',
        'js' => 'text/javascript',
        'mjs' => 'text/javascript',
        'css' => 'text/css',
        'json' => 'application/json',
        'wasm' => 'application/wasm',
        'map' => 'application/json',
        'txt' => 'text/plain',
        'xml' => 'application/xml',
        'svg' => 'image/svg+xml',
        'png' => 'image/png',
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        'avif' => 'image/avif',
        'ico' => 'image/x-icon',
        'bmp' => 'image/bmp',
        'mp3' => 'audio/mpeg',
        'ogg' => 'audio/ogg',
        'oga' => 'audio/ogg',
        'wav' => 'audio/wav',
        'm4a' => 'audio/mp4',
        'mp4' => 'video/mp4',
        'webm' => 'video/webm',
        'ttf' => 'font/ttf',
        'otf' => 'font/otf',
        'woff' => 'font/woff',
        'woff2' => 'font/woff2',
        'eot' => 'application/vnd.ms-fontobject',
        'glb' => 'model/gltf-binary',
        'gltf' => 'model/gltf+json',
        'atlas' => 'text/plain',
        'data' => 'application/octet-stream',
        'unityweb' => 'application/octet-stream',
        'pck' => 'application/octet-stream',
        'br' => 'application/octet-stream',
    ];

    public function __invoke(
        Request $request,
        Game $game,
        ?string $path = null
    ): BinaryFileResponse|RedirectResponse {
        abort_unless($game->isHosted() && filled($game->bundle_path), 404);

        // Drafts stay visible to administrators only.
        abort_unless($game->is_published || $request->user()?->is_admin, 404);

        // A browser resolves a relative asset URL against the *directory* of
        // the page URL. Served bare at ".../play", "css/game.css" would
        // resolve to ".../star-wars/css/game.css" and 404, so the entry is
        // always addressed by its filename.
        if ($path === null) {
            return redirect()->route('games.play', [
                'game' => $game->slug,
                'path' => $game->entry_path ?: 'index.html',
            ]);
        }

        $relative = $this->safeRelativePath($path);

        $disk = Storage::disk(GameBundleExtractor::DISK);
        $file = $game->bundle_path.'/'.$relative;

        abort_unless($disk->exists($file), 404);

        $absolute = $disk->path($file);

        // The bundle root is the boundary; refuse anything resolving outside
        // it, even if a symlink inside the bundle points away.
        $root = realpath($disk->path($game->bundle_path));
        $real = realpath($absolute);
        abort_if($root === false || $real === false || ! str_starts_with($real, $root.DIRECTORY_SEPARATOR), 404);

        return response()->file($absolute, [
            'Content-Type' => $this->mimeFor($relative),
            // Bundles are replaced wholesale, never edited in place.
            'Cache-Control' => 'private, max-age=300',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    /**
     * The path comes from the URL, so it is untrusted just like the archive
     * was. Traversal and absolute paths are rejected outright.
     */
    private function safeRelativePath(string $path): string
    {
        $path = ltrim(str_replace('\\', '/', $path), '/');

        abort_if($path === '' || str_contains($path, '://'), 404);

        foreach (explode('/', $path) as $segment) {
            abort_if($segment === '..', 404);
        }

        return $path;
    }

    private function mimeFor(string $path): string
    {
        $extension = strtolower(pathinfo($path, PATHINFO_EXTENSION));

        return self::MIME_TYPES[$extension] ?? 'application/octet-stream';
    }
}
