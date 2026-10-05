<?php

namespace App\Services\Google;

interface VerifiesGoogleIdTokens
{
    /** Null when the token is missing, expired, forged or for another app. */
    public function verify(string $idToken): ?GoogleAccount;

    /** False when no OAuth client IDs are configured for this deployment. */
    public function isConfigured(): bool;
}
