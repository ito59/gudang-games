<?php

namespace App\Models\Concerns;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

/**
 * An `image_path` that may hold an upload of ours or a path into the Flutter
 * bundle, and knows the difference.
 *
 * Seeded records point at assets shipped inside the app. Those are not on our
 * disk: they resolve to no URL and must never be deleted.
 */
trait HasUploadedImage
{
    public static function bootHasUploadedImage(): void
    {
        static::deleting(function (Model $model) {
            $model->deleteImageFile();
        });
    }

    public function getImageUrlAttribute(): ?string
    {
        if (blank($this->image_path) || $this->imageIsBundled()) {
            return null;
        }

        return Storage::disk('public')->url($this->image_path);
    }

    /** Ours to delete only when we stored it. */
    public function deleteImageFile(): void
    {
        if (filled($this->image_path) && ! $this->imageIsBundled()) {
            Storage::disk('public')->delete($this->image_path);
        }
    }

    private function imageIsBundled(): bool
    {
        return str_starts_with((string) $this->image_path, 'assets/');
    }
}
