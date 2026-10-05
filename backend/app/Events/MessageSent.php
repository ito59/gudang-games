<?php

namespace App\Events;

use App\Http\Resources\MessageResource;
use App\Models\Message;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Carries a new message to whoever is listening on the thread.
 *
 * `ShouldBroadcastNow`, not `ShouldBroadcast`: the latter queues, and a chat
 * message that waits for a worker cycle is not realtime — with no worker
 * running it never arrives at all. The cost is one outbound call inside the
 * send request, which is the right trade for a message.
 */
class MessageSent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Message $message) {}

    /**
     * @return array<int, PrivateChannel>
     */
    public function broadcastOn(): array
    {
        return [new PrivateChannel("conversation.{$this->message->conversation_id}")];
    }

    public function broadcastAs(): string
    {
        return 'message.sent';
    }

    /**
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        $message = $this->message->loadMissing(
            'author:id,name,username,accent_color,avatar_path'
        );

        return [
            'conversation_id' => $this->message->conversation_id,
            'message' => (new MessageResource($message))->resolve(),
        ];
    }
}
