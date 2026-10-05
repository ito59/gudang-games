<?php

namespace Tests\Feature\Api;

use Firebase\JWT\JWT;
use Google\Auth\AccessToken;
use Tests\TestCase;

/**
 * Proves this installation can actually verify an RS256 Google token.
 *
 * google/auth needs phpseclib to turn a JWK into a public key, and without it
 * every verification fails — indistinguishably, from the app's side, from a
 * forged token. That failure looks exactly like success in a test that only
 * feeds it rubbish, so this signs a real token with a known key and checks it
 * comes back verified.
 */
class GoogleTokenCryptoTest extends TestCase
{
    private string $certsFile;

    /** @var array{private: string, jwk: array<string, string>} */
    private array $key;

    protected function setUp(): void
    {
        parent::setUp();

        $resource = openssl_pkey_new([
            'private_key_bits' => 2048,
            'private_key_type' => OPENSSL_KEYTYPE_RSA,
        ]);
        openssl_pkey_export($resource, $private);
        $details = openssl_pkey_get_details($resource);

        $this->key = [
            'private' => $private,
            'jwk' => [
                'kty' => 'RSA',
                'alg' => 'RS256',
                'use' => 'sig',
                'kid' => 'test-key',
                'n' => $this->base64Url($details['rsa']['n']),
                'e' => $this->base64Url($details['rsa']['e']),
            ],
        ];

        $this->certsFile = tempnam(sys_get_temp_dir(), 'certs').'.json';
        file_put_contents(
            $this->certsFile,
            json_encode(['keys' => [$this->key['jwk']]]),
        );
    }

    protected function tearDown(): void
    {
        @unlink($this->certsFile);
        parent::tearDown();
    }

    private function base64Url(string $bytes): string
    {
        return rtrim(strtr(base64_encode($bytes), '+/', '-_'), '=');
    }

    private function token(array $overrides = []): string
    {
        return JWT::encode(
            $overrides + [
                'iss' => 'https://accounts.google.com',
                'aud' => 'web.apps.googleusercontent.com',
                'sub' => '104729',
                'email' => 'someone@gmail.com',
                'email_verified' => true,
                'iat' => time(),
                'exp' => time() + 3600,
            ],
            $this->key['private'],
            'RS256',
            'test-key',
        );
    }

    private function verify(string $token): array|false
    {
        // A fresh instance each time: the library caches the key set.
        return (new AccessToken)->verify($token, [
            'certsLocation' => $this->certsFile,
            'cacheKey' => 'crypto-test-'.uniqid(),
        ]);
    }

    public function test_a_correctly_signed_token_verifies(): void
    {
        $payload = $this->verify($this->token());

        $this->assertIsArray($payload, 'RS256 verification is not working');
        $this->assertSame('104729', $payload['sub']);
        $this->assertSame('web.apps.googleusercontent.com', $payload['aud']);
    }

    public function test_a_tampered_token_does_not_verify(): void
    {
        [$header, $body, $signature] = explode('.', $this->token());
        $claims = json_decode(JWT::urlsafeB64Decode($body), true);
        $claims['sub'] = '999';
        $forged = $header.'.'.$this->base64Url(json_encode($claims)).'.'.$signature;

        $this->assertFalse($this->verify($forged));
    }

    public function test_an_expired_token_does_not_verify(): void
    {
        $this->assertFalse(
            $this->verify($this->token(['exp' => time() - 60, 'iat' => time() - 3600])),
        );
    }

    public function test_a_token_from_the_wrong_issuer_does_not_verify(): void
    {
        $this->assertFalse($this->verify($this->token(['iss' => 'https://evil.example'])));
    }
}
