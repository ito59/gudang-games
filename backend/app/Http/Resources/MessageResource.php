<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'conversation_id' => $this->conversation_id,
            'body' => $this->body,
            'author' => [
                'id' => $this->author?->id,
                'name' => $this->author?->name,
                'handle' => $this->author?->username,
                'accent' => $this->author?->accent_color,
                'avatar' => $this->author?->avatar_url ?? $this->author?->avatar_path,
            ],
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
