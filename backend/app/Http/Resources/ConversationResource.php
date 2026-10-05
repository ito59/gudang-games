<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A thread as the messages list shows it: who it is with, what was said last,
 * and how much of it the viewer has not read.
 */
class ConversationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $viewer = $request->user();
        $other = $this->otherThan($viewer);
        $last = $this->latestMessage;

        return [
            'id' => $this->id,
            'with' => $other === null ? null : [
                'id' => $other->id,
                'name' => $other->name,
                'handle' => $other->username,
                'accent' => $other->accent_color,
                'avatar' => $other->avatar_url ?? $other->avatar_path,
                'playing' => $other->playing,
                'is_online' => $other->isOnline(),
            ],
            'last_message' => $last === null ? null : [
                'body' => $last->body,
                'mine' => $last->user_id === $viewer?->id,
                'created_at' => $last->created_at?->toIso8601String(),
            ],
            'unread' => (int) ($this->unread_count ?? 0),
            // How far the other person has read, so the viewer's own
            // messages can show whether they landed. Null means never
            // opened. Their own id, not "all of it": a message sent a moment
            // after they looked away has not been read.
            'their_last_read_id' => $other?->pivot?->last_read_message_id,
            'last_message_at' => $this->last_message_at?->toIso8601String(),
        ];
    }
}
