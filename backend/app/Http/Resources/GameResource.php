<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GameResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'slug' => $this->slug,
            'category' => $this->whenLoaded('category', fn () => $this->category?->name),
            // The slug is what the app filters on; the name is for display.
            'category_slug' => $this->whenLoaded('category', fn () => $this->category?->slug),
            'rating' => (float) $this->rating,
            'plays_count' => (int) $this->plays_count,
            // 'url' opens an external link; 'zip' opens a bundle we host.
            'source_type' => $this->source_type,
            'play_url' => $this->play_url,
            'trailer_url' => $this->trailer_url,
            'description' => $this->description,
            // Uploaded covers resolve to a URL; bundled asset paths pass through.
            'image' => $this->cover_url ?? $this->cover_path,
        ];
    }
}
