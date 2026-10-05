<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PostResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            // Only news has one; the app reads its absence as an ordinary post.
            'title' => $this->title,
            'body' => $this->body,
            'kind' => $this->kind,
            // Uploaded images resolve to a URL; bundled asset paths pass
            // through, the same way a game's cover does.
            'image' => $this->image_url ?? $this->image_path,
            'game_tag' => $this->whenLoaded('game', fn () => $this->game?->title),
            'likes' => $this->likes_count ?? $this->likes()->count(),
            'comments' => (int) ($this->comments_count ?? 0),
            'liked_by_me' => (bool) ($this->liked_by_me ?? false),
            'published_at' => $this->published_at?->toIso8601String(),
            'author' => [
                'id' => $this->author?->id,
                'name' => $this->author?->name,
                'handle' => $this->author?->username,
                'accent' => $this->author?->accent_color,
                'avatar' => $this->author?->avatar_url ?? $this->author?->avatar_path,
            ],
        ];
    }
}
