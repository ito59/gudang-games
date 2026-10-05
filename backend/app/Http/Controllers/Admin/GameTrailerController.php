<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Game;
use App\Services\GameBundleExtractor;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Trailer uploads live on their own page.
 *
 * Videos are large, and a slow upload that fails should not take the rest of
 * a game's edits down with it — keeping this separate means the metadata form
 * always saves instantly.
 */
class GameTrailerController extends Controller
{
    public function edit(Game $game): Response
    {
        return Inertia::render('Admin/Games/Trailer', [
            'game' => $game->only([
                'id', 'title', 'slug', 'trailer_mime', 'trailer_size', 'trailer_url',
            ]),
            'maxTrailerMb' => intdiv($this->maxKilobytes(), 1024),
        ]);
    }

    public function update(Request $request, Game $game): RedirectResponse
    {
        $this->assertUploadSucceeded($request);

        $request->validate([
            'trailer' => [
                'required', 'file',
                'mimetypes:video/mp4,video/webm,video/quicktime',
                'max:'.$this->maxKilobytes(),
            ],
        ], [
            'trailer.mimetypes' => 'The trailer must be an MP4, WebM or MOV video.',
            'trailer.max' => sprintf(
                'The trailer must be %d MB or smaller.',
                intdiv($this->maxKilobytes(), 1024)
            ),
        ]);

        $file = $request->file('trailer');

        // Replacing drops the previous file rather than leaving it orphaned.
        $game->deleteTrailer();

        $game->forceFill([
            'trailer_path' => $file->store(Game::TRAILER_DIRECTORY, GameBundleExtractor::DISK),
            'trailer_mime' => $file->getMimeType(),
            'trailer_size' => $file->getSize(),
        ])->save();

        return to_route('admin.games.trailer.edit', $game)
            ->with('success', 'Trailer uploaded.');
    }

    public function destroy(Game $game): RedirectResponse
    {
        $game->deleteTrailer();
        $game->forceFill([
            'trailer_path' => null,
            'trailer_mime' => null,
            'trailer_size' => null,
        ])->save();

        return back()->with('success', 'Trailer removed.');
    }

    /** Follows php.ini so the two limits cannot drift apart. */
    private function maxKilobytes(): int
    {
        $limit = min(
            $this->iniBytes((string) ini_get('upload_max_filesize')),
            $this->iniBytes((string) ini_get('post_max_size'))
        );

        return max(1024, intdiv($limit, 1024) - 512);
    }

    private function iniBytes(string $value): int
    {
        $value = trim($value);
        if ($value === '') {
            return PHP_INT_MAX;
        }

        $number = (int) $value;

        return match (strtolower(substr($value, -1))) {
            'g' => $number * 1024 ** 3,
            'm' => $number * 1024 ** 2,
            'k' => $number * 1024,
            default => $number,
        };
    }

    /**
     * PHP discards an oversized upload before validation runs, which would
     * otherwise read as "the trailer field is required".
     */
    private function assertUploadSucceeded(Request $request): void
    {
        $file = $request->files->get('trailer');

        if (! $file instanceof UploadedFile || $file->isValid()) {
            return;
        }

        $message = match ($file->getError()) {
            UPLOAD_ERR_INI_SIZE, UPLOAD_ERR_FORM_SIZE => sprintf(
                'The video is larger than this server accepts '
                .'(upload_max_filesize = %s, post_max_size = %s). '
                .'Raise both in php.ini and restart PHP.',
                ini_get('upload_max_filesize'),
                ini_get('post_max_size')
            ),
            UPLOAD_ERR_PARTIAL => 'The upload was interrupted. Please try again.',
            default => 'The upload did not complete: '.$file->getErrorMessage(),
        };

        throw ValidationException::withMessages(['trailer' => $message]);
    }
}
