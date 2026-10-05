<?php

namespace App\Services\Moderation;

/**
 * What the moderator decided, and what to tell each of the two audiences:
 * [$message] is read by the person who wrote the text, [$match] by whoever
 * later reviews the log. They are separate because telling a sender exactly
 * which word tripped the filter is a lesson in how to get past it.
 */
final class Verdict
{
    public const profanity = 'profanity';

    public const spam = 'spam';

    private function __construct(
        public readonly bool $allowed,
        public readonly ?string $reason = null,
        public readonly ?string $message = null,
        public readonly ?string $match = null,
    ) {}

    public static function ok(): self
    {
        return new self(allowed: true);
    }

    public static function reject(string $reason, string $message, ?string $match = null): self
    {
        return new self(
            allowed: false,
            reason: $reason,
            message: $message,
            match: $match,
        );
    }

    public function rejected(): bool
    {
        return ! $this->allowed;
    }
}
