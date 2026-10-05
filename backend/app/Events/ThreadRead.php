<?php

namespace App\Events;

use App\Models\Conversation;
use App\Models\User;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Somebody has caught up on a thread.
 *
 * The other seat needs this to turn its ticks blue while it is looking. It
 * carries how far they have read rather than "all of it", so a message sent
 * a moment after they looked away is not marked read.
 */
class ThreadRead implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Conversation $conversation,
        public User $reader,
        public ?int $lastReadMessageId,
    ) {}

    /**
     * @return array<int, PrivateChannel>
     */
    public function broadcastOn(): array
    {
        return [new PrivateChannel("conversation.{$this->conversation->id}")];
    }

    public function broadcastAs(): string
    {
        return 'thread.read';
    }

    /**
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        return [
            'conversation_id' => $this->conversation->id,
            'reader_id' => $this->reader->id,
            'last_read_message_id' => $this->lastReadMessageId,
        ];
    }
}
