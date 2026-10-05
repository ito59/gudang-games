<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Services\ImageStore;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

/**
 * The signed-in member's profile photo.
 *
 * Its own controller rather than another field on `PATCH /me`: an upload can
 * fail on its own terms — too large, wrong type, a dropped connection — and
 * that should not cost somebody the name and bio they were editing.
 */
class AvatarController extends Controller
{
    public function store(Request $request): UserResource
    {
        $request->validate([
            'photo' => [
                'required',
                'image',
                'mimes:jpg,jpeg,png,webp',
                // Phone cameras produce far larger files than a 96px avatar
                // needs, but rejecting them outright would be baffling.
                'max:8192',
            ],
        ], [
            'photo.max' => 'That photo is larger than 8 MB.',
            'photo.mimes' => 'Use a JPG, PNG or WebP image.',
        ]);

        $user = $request->user();
        $previous = $user->avatar_path;

        $user->update([
            // Shown at 98 pixels at its largest; 512 leaves room for a
            // high-density screen and nothing more.
            'avatar_path' => (new ImageStore(maxEdge: 512))
                ->store($request->file('photo'), 'avatars'),
        ]);

        $this->forget($previous);

        return new UserResource($user);
    }

    /** Back to initials, and the file goes with it. */
    public function destroy(Request $request): UserResource
    {
        $user = $request->user();
        $previous = $user->avatar_path;

        $user->update(['avatar_path' => null]);

        $this->forget($previous);

        return new UserResource($user);
    }

    /**
     * Deletes a replaced file so the disk does not fill with photos nothing
     * points at. Seeded bundle paths are not ours to delete.
     */
    private function forget(?string $path): void
    {
        if (blank($path) || str_starts_with($path, 'assets/')) {
            return;
        }

        Storage::disk('public')->delete($path);
    }
}
