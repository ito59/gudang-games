<?php

namespace Tests\Feature\Api;

use App\Services\Google\GoogleIdTokenVerifier;
use Google\Auth\AccessToken;
use Tests\TestCase;

/**
 * Covers the parts of verification this app owns. The signature, issuer and
 * expiry checks belong to google/auth, so the library is stubbed at that seam
 * and what is tested here is what we do with the payload it returns.
 */
class GoogleIdTokenVerifierTest extends TestCase
{
    private const OURS = 'web-client.apps.googleusercontent.com';

    private function verifier(array $payload, array $clientIds = [self::OURS]): GoogleIdTokenVerifier
    {
        config(['services.google.client_ids' => $clientIds]);

        $tokens = new class($payload) extends AccessToken
        {
            public function __construct(private readonly mixed $payload)
            {
                parent::__construct();
            }

            public function verify($token, array $options = [])
            {
                return $this->payload;
            }
        };

        return new GoogleIdTokenVerifier($tokens);
    }

    private function payload(array $overrides = []): array
    {
        return $overrides + [
            'aud' => self::OURS,
            'sub' => '104729',
            'email' => 'Someone@Gmail.com',
            'email_verified' => true,
            'name' => 'Some One',
            'picture' => 'https://lh3.googleusercontent.com/a/photo',
        ];
    }

    public function test_it_accepts_a_token_for_one_of_our_clients(): void
    {
        $account = $this->verifier($this->payload())->verify('token');

        $this->assertNotNull($account);
        $this->assertSame('104729', $account->subject);
        $this->assertTrue($account->emailVerified);
        $this->assertSame('Some One', $account->name);
    }

    public function test_it_lowercases_the_email(): void
    {
        // Our own lookups compare against stored, lowercased addresses.
        $this->assertSame(
            'someone@gmail.com',
            $this->verifier($this->payload())->verify('token')->email,
        );
    }

    public function test_it_rejects_a_token_minted_for_another_app(): void
    {
        // A valid, correctly signed Google token is still not proof of a sign
        // in to *this* app: without this check any Google app's token passes.
        $payload = $this->payload(['aud' => 'someone-elses.apps.googleusercontent.com']);

        $this->assertNull($this->verifier($payload)->verify('token'));
    }

    public function test_it_accepts_any_of_several_configured_clients(): void
    {
        $payload = $this->payload(['aud' => 'ios-client.apps.googleusercontent.com']);

        $account = $this->verifier($payload, [
            self::OURS,
            'ios-client.apps.googleusercontent.com',
        ])->verify('token');

        $this->assertNotNull($account);
    }

    public function test_it_refuses_everything_when_no_client_is_configured(): void
    {
        $verifier = $this->verifier($this->payload(), clientIds: []);

        $this->assertFalse($verifier->isConfigured());
        $this->assertNull($verifier->verify('token'));
    }

    public function test_it_rejects_a_payload_without_a_subject_or_email(): void
    {
        $this->assertNull($this->verifier(['aud' => self::OURS, 'email' => 'a@b.c'])->verify('t'));
        $this->assertNull($this->verifier(['aud' => self::OURS, 'sub' => '1'])->verify('t'));
    }

    public function test_it_reads_the_string_form_of_email_verified(): void
    {
        // Google has sent this claim as the string "true" in the past.
        $account = $this->verifier($this->payload(['email_verified' => 'true']))->verify('token');

        $this->assertTrue($account->emailVerified);
    }

    public function test_a_missing_email_verified_claim_is_not_verified(): void
    {
        $payload = $this->payload();
        unset($payload['email_verified']);

        $this->assertFalse($this->verifier($payload)->verify('token')->emailVerified);
    }

    public function test_a_library_failure_is_a_refusal_not_an_exception(): void
    {
        config(['services.google.client_ids' => [self::OURS]]);

        $throwing = new class extends AccessToken
        {
            public function verify($token, array $options = [])
            {
                throw new \UnexpectedValueException('Issuer does not match');
            }
        };

        $this->assertNull((new GoogleIdTokenVerifier($throwing))->verify('token'));
    }
}
