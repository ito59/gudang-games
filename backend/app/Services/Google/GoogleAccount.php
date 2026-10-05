<?php

namespace App\Services\Google;

/** The claims we care about from a verified Google ID token. */
final class GoogleAccount
{
    public function __construct(
        public readonly string $subject,
        public readonly string $email,
        public readonly bool $emailVerified,
        public readonly ?string $name,
        public readonly ?string $picture,
    ) {}

    /** @param array<string, mixed> $payload */
    public static function fromPayload(array $payload): ?self
    {
        $subject = $payload['sub'] ?? null;
        $email = $payload['email'] ?? null;

        if (! is_string($subject) || $subject === '' || ! is_string($email) || $email === '') {
            return null;
        }

        return new self(
            subject: $subject,
            // Google normalises this already; lowercasing keeps our own
            // lookups consistent with the accounts the seeder made.
            email: mb_strtolower($email),
            emailVerified: ($payload['email_verified'] ?? false) === true
                || ($payload['email_verified'] ?? null) === 'true',
            name: is_string($payload['name'] ?? null) ? $payload['name'] : null,
            picture: is_string($payload['picture'] ?? null) ? $payload['picture'] : null,
        );
    }
}
