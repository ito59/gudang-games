<?php

namespace App\Http\Controllers\Concerns;

use App\Models\Concerns\HasUploadedImage;
use App\Services\ImageStore;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;

/**
 * The admin side of [HasUploadedImage]: one picker, one Remove, and no
 * orphaned files left behind by an edit.
 */
trait SyncsUploadedImage
{
    /**
     * @return array<string, array<int, mixed>>
     */
    protected function imageRules(): array
    {
        return [
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
            'remove_image' => ['boolean'],
        ];
    }

    /**
     * @return array<string, string>
     */
    protected function imageMessages(): array
    {
        return [
            'image.max' => 'The image must be 4 MB or smaller.',
            'image.mimes' => 'The image must be a JPG, PNG or WebP image.',
        ];
    }

    /**
     * Applies an uploaded image, or clears the current one. A request that
     * mentions neither leaves what is already stored alone.
     *
     * @param  Model&HasUploadedImage  $model
     */
    protected function syncImage(Request $request, Model $model, string $folder): void
    {
        if ($request->boolean('remove_image')) {
            $model->deleteImageFile();
            $model->image_path = null;

            return;
        }

        if (! $request->hasFile('image')) {
            return;
        }

        $model->deleteImageFile();
        // Wider than a cover: a news article's image spans the page.
        $model->image_path = (new ImageStore(maxEdge: 1600))
            ->store($request->file('image'), $folder);
    }
}
