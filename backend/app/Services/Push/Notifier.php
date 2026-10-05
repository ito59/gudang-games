<?php

namespace App\Services\Push;

use App\Models\Message;
use App\Models\Post;
use Illuminate\Support\Str;
use Throwable;

/**
 * Decides who is told what, and never lets the telling break the thing that
 * prompted it.
 *
 * A message is sent and an article is published whether or not a phone can
 * be reached. Everything here is wrapped: a notification is the least
 * important part of either request.
 */
class Notifier
{
    public function __construct(private readonly Push $push) {}

    /** The other seat, unless they have asked not to hear about chat. */
    public function messageSent(Message $message): void
    {
        $this->quietly(function () use ($message) {
            $conversation = $message->conversation()->with('participants')->first();
            if ($conversation === null) {
                return;
            }

            $sender = $message->author;
            $recipient = $conversation->otherThan($sender);

            if ($recipient === null || ! $recipient->notify_chat) {
                return;
            }

            $this->push->toUser($recipient, new PushMessage(
                title: $sender?->name ?? 'New message',
                body: Str::limit($message->body, 120),
                data: [
                    'type' => 'chat',
                    'conversation_id' => (string) $conversation->id,
                ],
            ));
        });
    }

    /**
     * Everybody who wants news, in one call.
     *
     * By topic rather than by walking every member: the number of installs is
     * not the server's problem to loop over, and a member who turned news off
     * has unsubscribed from the topic on their own device.
     */
    public function newsPublished(Post $post): void
    {
        $this->quietly(function () use ($post) {
            $this->push->toTopic(
                (string) config('push.news_topic'),
                new PushMessage(
                    title: $post->title ?? 'News from the team',
                    body: Str::limit(strip_tags($post->body), 120),
                    data: ['type' => 'news', 'post_id' => (string) $post->id],
                ),
            );
        });
    }

    private function quietly(callable $work): void
    {
        try {
            $work();
        } catch (Throwable $e) {
            report($e);
        }
    }
}
