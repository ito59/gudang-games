<?php

namespace App\Http\Resources;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'handle' => $this->username,
            'bio' => $this->bio,
            'location' => $this->location,
            // Uploaded photos resolve to a URL; bundled asset paths pass
            // through, the same way a game's cover does.
            'avatar' => $this->avatar_url ?? $this->avatar_path,
            'google_avatar' => $this->google_avatar_url,
            'accent' => $this->accent_color,
            'playing' => $this->playing,
            'is_online' => $this->isOnline(),
            'games_owned' => $this->games_owned,
            'hours_played' => $this->hours_played,
            'achievements' => $this->achievements,
            // Told from the viewer's side, so the app can label one button:
            // self | friends | requested | pending | none.
            'friendship' => $this->friendshipStateFor($request->user('sanctum')),
            // Whether the viewer blocked this member — their own doing, so
            // they may be told. Being blocked *by* them is deliberately not
            // reported: that is the other member's business.
            'blocked' => $this->blockedBy($request->user('sanctum')),
        ];
    }

    /**
     * Whether [$viewer] has blocked this member.
     *
     * One-directional on purpose: the other half — whether this member has
     * blocked the viewer — is the other member's business, and answering it
     * here would be the one thing a quiet block must not do.
     */
    private function blockedBy(?User $viewer): bool
    {
        return $viewer !== null
            && ! $viewer->is($this->resource)
            && $viewer->hasBlocked($this->resource);
    }
}
