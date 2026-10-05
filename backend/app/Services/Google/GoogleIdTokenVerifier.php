<?php

namespace App\Services\Google;

use Google\Auth\AccessToken;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Checks an ID token against Google's published signing keys.
 *
 * The token is the only evidence the app supplies, so nothing in it is trusted
 * before the signature, issuer and expiry check out — and the audience has to
 * name one of our own OAuth clients, or any Google app's token would pass.
 */
final class GoogleIdTokenVerifier implements VerifiesGoogleIdTokens
{
    public function __construct(private readonly AccessToken $tokens) {}

    public function isConfigured(): bool
    {
        return $this->clientIds() !== [];
    }

    public function verify(string $idToken): ?GoogleAccount
    {
        $allowed = $this->clientIds();
        if ($allowed === []) {
            return null;
        }

        try {
            // Signature, issuer and expiry. Audience is checked below instead,
            // because a deployment has several client IDs (web, iOS) and this
            // call only takes one.
            $payload = $this->tokens->verify($idToken);
        } catch (Throwable $error) {
            Log::warning('Google ID token could not be verified.', [
                'reason' => $error->getMessage(),
            ]);

            return null;
        }

        if (! is_array($payload)) {
            return null;
        }

        $audience = $payload['aud'] ?? null;
        if (! is_string($audience) || ! in_array($audience, $allowed, true)) {
            Log::warning('Google ID token was issued for another app.', [
                'aud' => $audience,
            ]);

            return null;
        }

        return GoogleAccount::fromPayload($payload);
    }

    /** @return list<string> */
    private function clientIds(): array
    {
        return array_values(config('services.google.client_ids', []));
    }
}
