<?php

namespace Tests\Support;

use App\Models\User;
use App\Services\Push\Push;
use App\Services\Push\PushMessage;

/** A [Push] that keeps what it was asked to send. */
class RecordingPush implements Push
{
    /** @var array<int, array{target: string, message: PushMessage}> */
    public array $sent = [];

    public bool $configured = true;

    public function toUser(User $user, PushMessage $message): void
    {
        $this->sent[] = ['target' => "user:{$user->id}", 'message' => $message];
    }

    public function toTopic(string $topic, PushMessage $message): void
    {
        $this->sent[] = ['target' => "topic:{$topic}", 'message' => $message];
    }

    public function isConfigured(): bool
    {
        return $this->configured;
    }

    /** @return array<int, string> */
    public function targets(): array
    {
        return array_column($this->sent, 'target');
    }
}
