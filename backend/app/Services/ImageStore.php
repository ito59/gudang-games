<?php

namespace App\Services;

use GdImage;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Throwable;

/**
 * Stores an uploaded image, shrinking it first when it is larger than the app
 * will ever draw it.
 *
 * A phone camera produces a 4000px, 6 MB photo; a game cover is shown at a few
 * hundred pixels. Keeping the original costs the server disk and every viewer
 * their bandwidth, for detail nobody sees.
 *
 * Shrinking never costs an upload: if the image cannot be read — no GD on the
 * server, an unusual encoding, anything at all — the original is stored as it
 * arrived. A slightly heavy cover is a much smaller problem than an admin who
 * cannot save one.
 */
class ImageStore
{
    public function __construct(
        /** Longest edge, in pixels. Smaller images are left alone. */
        private readonly int $maxEdge = 1600,
        /** JPEG and WebP quality; PNG keeps its own compression. */
        private readonly int $quality = 82,
    ) {}

    /** Returns the stored path, relative to the disk. */
    public function store(UploadedFile $file, string $folder, string $disk = 'public'): string
    {
        $shrunk = $this->shrink($file);

        if ($shrunk === null) {
            return $file->store($folder, $disk);
        }

        $path = $folder.'/'.Str::random(40).'.'.$this->extensionFor($file);
        Storage::disk($disk)->put($path, $shrunk);

        return $path;
    }

    /** Encoded bytes of the smaller image, or null to keep the original. */
    private function shrink(UploadedFile $file): ?string
    {
        if (! function_exists('imagecreatetruecolor')) {
            return null;
        }

        try {
            $source = $this->read($file);
            if ($source === null) {
                return null;
            }

            [$image, $width, $height] = $source;

            $scale = $this->maxEdge / max($width, $height);
            if ($scale >= 1) {
                // Already small enough. Re-encoding would only lose detail.
                imagedestroy($image);

                return null;
            }

            $resized = imagescale($image, (int) round($width * $scale), (int) round($height * $scale));
            imagedestroy($image);

            if ($resized === false) {
                return null;
            }

            $bytes = $this->encode($resized, $this->extensionFor($file));
            imagedestroy($resized);

            return $bytes;
        } catch (Throwable) {
            return null;
        }
    }

    /**
     * @return array{0: GdImage, 1: int, 2: int}|null
     */
    private function read(UploadedFile $file): ?array
    {
        $path = $file->getRealPath();
        if ($path === false) {
            return null;
        }

        $image = @imagecreatefromstring((string) file_get_contents($path));
        if ($image === false) {
            return null;
        }

        // Phones record orientation in EXIF rather than rotating the pixels,
        // so a portrait photo arrives sideways unless it is turned here.
        $image = $this->straighten($image, $path);

        // Alpha has to be asked for, or a transparent PNG comes out black.
        imagealphablending($image, false);
        imagesavealpha($image, true);

        return [$image, imagesx($image), imagesy($image)];
    }

    private function straighten(GdImage $image, string $path): GdImage
    {
        if (! function_exists('exif_read_data')) {
            return $image;
        }

        $exif = @exif_read_data($path);
        $degrees = match ($exif['Orientation'] ?? 1) {
            3 => 180,
            6 => -90,
            8 => 90,
            default => 0,
        };

        if ($degrees === 0) {
            return $image;
        }

        $rotated = imagerotate($image, $degrees, 0);

        return $rotated === false ? $image : $rotated;
    }

    private function encode(GdImage $image, string $extension): ?string
    {
        ob_start();

        $ok = match ($extension) {
            'png' => imagepng($image, null, 6),
            'webp' => imagewebp($image, null, $this->quality),
            default => imagejpeg($image, null, $this->quality),
        };

        $bytes = ob_get_clean();

        return $ok && is_string($bytes) && $bytes !== '' ? $bytes : null;
    }

    /** The upload's own extension, so its type never changes underneath it. */
    private function extensionFor(UploadedFile $file): string
    {
        $extension = strtolower($file->getClientOriginalExtension() ?: 'jpg');

        return match ($extension) {
            'png' => 'png',
            'webp' => 'webp',
            default => 'jpg',
        };
    }
}
