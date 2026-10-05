<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use ZipArchive;

/**
 * Unpacks an uploaded HTML5 game bundle into protected storage.
 *
 * Bundles live on the `local` disk (storage/app/private), which the web server
 * never serves directly — they are streamed by GamePlayController instead, so
 * access stays under the application's control.
 *
 * A zip from an admin is still untrusted input, so this refuses anything that
 * could escape the target directory or be executed by the server.
 */
class GameBundleExtractor
{
    /** Where bundles land, relative to the protected disk. */
    public const DIRECTORY = 'games';

    /** The protected disk. Never `public`. */
    public const DISK = 'local';

    /** Guards against a zip bomb: 300 MB unpacked, 5000 files. */
    public const MAX_UNPACKED_BYTES = 300 * 1024 * 1024;

    public const MAX_ENTRIES = 5000;

    /**
     * Anything the server might run rather than serve. Files under the public
     * disk are reachable over HTTP, so a stray .php would be executable.
     */
    public const BLOCKED_EXTENSIONS = [
        'php', 'php3', 'php4', 'php5', 'php7', 'php8', 'phtml', 'phps', 'phar',
        'cgi', 'pl', 'py', 'rb', 'sh', 'bash', 'exe', 'dll', 'so', 'dylib',
        'jsp', 'asp', 'aspx', 'htaccess',
    ];

    /** Accepted entry file names, compared case-insensitively. */
    private const ENTRY_NAMES = ['index.html', 'index.htm'];

    /**
     * @return array{path: string, entry: string, size: int}
     *
     * @throws RuntimeException when the archive is unusable or unsafe
     */
    public function extract(UploadedFile $file, string $slug): array
    {
        $zip = new ZipArchive;

        if ($zip->open($file->getRealPath()) !== true) {
            throw new RuntimeException('The archive could not be opened. Is it a valid ZIP file?');
        }

        try {
            $plan = $this->plan($zip);
            $directory = self::DIRECTORY.'/'.$slug;

            // A re-upload replaces the previous bundle outright.
            Storage::disk(self::DISK)->deleteDirectory($directory);

            $absolute = Storage::disk(self::DISK)->path($directory);
            $this->write($zip, $plan['files'], $absolute, $plan['strip']);

            return [
                // `entry` is relative to the bundle, so the play route can
                // resolve any file the same way.
                'path' => $directory,
                'entry' => $plan['entry'],
                'size' => $plan['size'],
            ];
        } finally {
            $zip->close();
        }
    }

    /**
     * Validates every entry up front so nothing is written when the archive
     * turns out to be bad halfway through.
     *
     * @return array{files: list<string>, entry: string, strip: string, size: int}
     */
    private function plan(ZipArchive $zip): array
    {
        if ($zip->numFiles > self::MAX_ENTRIES) {
            throw new RuntimeException('The archive holds too many files (limit '.self::MAX_ENTRIES.').');
        }

        $files = [];
        $total = 0;

        for ($i = 0; $i < $zip->numFiles; $i++) {
            $stat = $zip->statIndex($i);
            $name = $stat['name'];

            // Directory entries carry no content.
            if (str_ends_with($name, '/')) {
                continue;
            }

            // Editor and OS noise, not part of the game.
            if (str_starts_with($name, '__MACOSX/') || basename($name) === '.DS_Store') {
                continue;
            }

            $this->assertSafePath($name);
            $this->assertAllowedExtension($name);

            $total += $stat['size'];
            if ($total > self::MAX_UNPACKED_BYTES) {
                throw new RuntimeException('The archive unpacks to more than '
                    .round(self::MAX_UNPACKED_BYTES / 1024 / 1024).' MB.');
            }

            $files[] = $name;
        }

        if ($files === []) {
            throw new RuntimeException('The archive is empty.');
        }

        [$strip, $entry] = $this->locateRoot($files);

        // Only what sits under the entry point's folder is the game.
        $files = array_values(array_filter(
            $files,
            fn (string $file) => $strip === '' || str_starts_with($file, $strip)
        ));

        return ['files' => $files, 'entry' => $entry, 'strip' => $strip, 'size' => $total];
    }

    /**
     * Rejects "zip slip": entries that would resolve outside the target
     * directory, whether by absolute path, traversal or a stream wrapper.
     */
    private function assertSafePath(string $name): void
    {
        $normalised = str_replace('\\', '/', $name);

        if (str_starts_with($normalised, '/') || preg_match('#^[a-zA-Z]:#', $normalised)) {
            throw new RuntimeException("The archive contains an absolute path: {$name}");
        }

        if (str_contains($normalised, '://')) {
            throw new RuntimeException("The archive contains an unsafe path: {$name}");
        }

        foreach (explode('/', $normalised) as $segment) {
            if ($segment === '..') {
                throw new RuntimeException("The archive tries to write outside its folder: {$name}");
            }
        }
    }

    private function assertAllowedExtension(string $name): void
    {
        $extension = strtolower(pathinfo($name, PATHINFO_EXTENSION));

        if ($extension === '' && str_starts_with(basename($name), '.')) {
            // e.g. ".htaccess" — pathinfo reports no extension for those.
            $extension = strtolower(ltrim(basename($name), '.'));
        }

        if (in_array($extension, self::BLOCKED_EXTENSIONS, true)) {
            throw new RuntimeException("The archive contains a file type that cannot be hosted: {$name}");
        }
    }

    /**
     * Finds the game's entry point and the folder it lives in.
     *
     * Real archives are not tidy: build output lands in `dist/game/`, people
     * zip a folder alongside a `docs/` sibling, and some name the file
     * `Index.html`. The shallowest index wins, and its folder becomes the
     * bundle root.
     *
     * @param  list<string>  $files
     * @return array{0: string, 1: string} [strip prefix, entry relative to it]
     */
    private function locateRoot(array $files): array
    {
        $best = null;
        $bestDepth = PHP_INT_MAX;

        foreach ($files as $file) {
            if (! in_array(strtolower(basename($file)), self::ENTRY_NAMES, true)) {
                continue;
            }

            $depth = substr_count($file, '/');
            if ($depth < $bestDepth || ($depth === $bestDepth && strlen($file) < strlen((string) $best))) {
                $best = $file;
                $bestDepth = $depth;
            }
        }

        if ($best === null) {
            throw new RuntimeException(
                'No index.html found anywhere in the archive. A game bundle must contain one.'
            );
        }

        $directory = dirname($best);
        $strip = $directory === '.' ? '' : $directory.'/';

        return [$strip, basename($best)];
    }

    /**
     * @param  list<string>  $files
     */
    private function write(ZipArchive $zip, array $files, string $absolute, string $strip): void
    {
        foreach ($files as $name) {
            $relative = $strip === '' ? $name : substr($name, strlen($strip));
            if ($relative === '' || $relative === false) {
                continue;
            }

            $target = $absolute.'/'.$relative;
            $directory = dirname($target);

            if (! is_dir($directory) && ! mkdir($directory, 0755, true) && ! is_dir($directory)) {
                throw new RuntimeException("Could not create {$directory}.");
            }

            $stream = $zip->getStream($name);
            if ($stream === false) {
                throw new RuntimeException("Could not read {$name} from the archive.");
            }

            $out = fopen($target, 'wb');
            stream_copy_to_stream($stream, $out);
            fclose($out);
            fclose($stream);
        }
    }
}
