<?php

namespace App\Services\Push;

use App\Models\User;
use Illuminate\Support\Facades\Log;

/**
 * Stands in until Firebase is configured.
 *
 * Writes what it would have sent rather than throwing: a deployment without
 * push credentials should still send messages and publish news, just without
 * the phone buzzing. The log line is what makes the difference visible
 * instead of silent.
 */
class LogPush implements Push
{
    public function toUser(User $user, PushMessage $message): void
    {
        $this->note("user {$user->id}", $message);
    }

    public function toTopic(string $topic, PushMessage $message): void
    {
        $this->note("topic {$topic}", $message);
    }

    public function isConfigured(): bool
    {
        return false;
    }

    private function note(string $target, PushMessage $message): void
    {
        Log::info('push not sent (no FCM credentials): '.$target, [
            'title' => $message->title,
            'body' => $message->body,
        ]);
    }
}
