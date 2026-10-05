<?php

namespace App\Services\Push;

use App\Models\User;

/**
 * Sending a notification to a phone.
 *
 * An interface because the app has to work before anybody has set up
 * Firebase: [LogPush] stands in until credentials exist, so every caller can
 * be written, run and tested today rather than waiting on a console.
 */
interface Push
{
    /** Every install this member is signed in on. */
    public function toUser(User $user, PushMessage $message): void;

    /** Everybody subscribed to a topic, in one call however many that is. */
    public function toTopic(string $topic, PushMessage $message): void;

    /** Whether this deployment can actually deliver anything. */
    public function isConfigured(): bool;
}
