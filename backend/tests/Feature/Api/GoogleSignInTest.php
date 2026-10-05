<?php

namespace Tests\Feature\Api;

use App\Models\User;
use App\Services\Google\GoogleAccount;
use App\Services\Google\VerifiesGoogleIdTokens;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GoogleSignInTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config(['services.google.client_ids' => ['web-client.apps.googleusercontent.com']]);
    }

    /** Stands in for Google: the real verifier is exercised separately. */
    private function fakeVerifier(?GoogleAccount $account, bool $configured = true): void
    {
        $this->swap(VerifiesGoogleIdTokens::class, new class($account, $configured) implements VerifiesGoogleIdTokens
        {
            public function __construct(
                private readonly ?GoogleAccount $account,
                private readonly bool $configured,
            ) {}

            public function isConfigured(): bool
            {
                return $this->configured;
            }

            public function verify(string $idToken): ?GoogleAccount
            {
                return $idToken === 'good-token' ? $this->account : null;
            }
        });
    }

    private function account(array $overrides = []): GoogleAccount
    {
        return new GoogleAccount(
            subject: $overrides['subject'] ?? '104729',
            email: $overrides['email'] ?? 'newcomer@gmail.com',
            emailVerified: $overrides['emailVerified'] ?? true,
            name: $overrides['name'] ?? 'New Comer',
            picture: $overrides['picture'] ?? 'https://lh3.googleusercontent.com/a/photo',
        );
    }

    private function signIn(string $token = 'good-token')
    {
        return $this->postJson('/api/v1/auth/google', [
            'id_token' => $token,
            'device_name' => 'bandar-games-app',
        ]);
    }

    public function test_a_first_google_sign_in_creates_an_account(): void
    {
        $this->fakeVerifier($this->account());

        $response = $this->signIn()
            ->assertOk()
            ->assertJsonPath('created', true)
            ->assertJsonPath('user.name', 'New Comer')
            ->assertJsonPath('user.handle', 'newcomer');

        $user = User::firstWhere('email', 'newcomer@gmail.com');
        $this->assertSame('104729', $user->google_id);
        $this->assertNotNull($user->email_verified_at);
        $this->assertNull($user->password, 'a Google-only account has no password');
        $this->assertNotEmpty($response->json('token'));
    }

    public function test_the_issued_token_works_on_a_protected_route(): void
    {
        $this->fakeVerifier($this->account());

        $token = $this->signIn()->json('token');

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/me')
            ->assertOk()
            ->assertJsonPath('data.handle', 'newcomer');
    }

    public function test_signing_in_again_reuses_the_same_account(): void
    {
        $this->fakeVerifier($this->account());

        $this->signIn()->assertJsonPath('created', true);
        $this->signIn()->assertJsonPath('created', false);

        $this->assertSame(1, User::where('email', 'newcomer@gmail.com')->count());
    }

    public function test_a_google_account_links_to_a_matching_password_account(): void
    {
        $existing = User::factory()->create([
            'email' => 'newcomer@gmail.com',
            'username' => 'oldhandle',
        ]);

        $this->fakeVerifier($this->account());

        $this->signIn()
            ->assertOk()
            ->assertJsonPath('created', false)
            // The account they already had, not a second one under a new handle.
            ->assertJsonPath('user.handle', 'oldhandle');

        $this->assertSame(1, User::count());
        $this->assertSame('104729', $existing->fresh()->google_id);
    }

    public function test_an_unverified_google_email_is_refused(): void
    {
        User::factory()->create(['email' => 'newcomer@gmail.com']);

        $this->fakeVerifier($this->account(['emailVerified' => false]));

        // Otherwise claiming an address would be enough to take the account.
        $this->signIn()->assertStatus(422);
        $this->assertNull(User::firstWhere('email', 'newcomer@gmail.com')->google_id);
    }

    public function test_a_token_that_does_not_verify_is_refused(): void
    {
        $this->fakeVerifier($this->account());

        $this->signIn('forged-token')
            ->assertStatus(422)
            ->assertJsonValidationErrors('id_token');

        $this->assertSame(0, User::count());
    }

    public function test_a_suspended_account_cannot_sign_in_with_google(): void
    {
        $user = User::factory()->create([
            'email' => 'newcomer@gmail.com',
            'is_active' => false,
        ]);

        $this->fakeVerifier($this->account());

        $this->signIn()->assertStatus(422);
        // The refusal must not have linked the identity on the way out.
        $this->assertNull($user->fresh()->google_id);
    }

    public function test_the_endpoint_reports_when_google_is_not_enabled(): void
    {
        $this->fakeVerifier($this->account(), configured: false);

        $this->signIn()
            ->assertStatus(503)
            ->assertJsonPath('message', 'Google sign-in is not enabled on this server.');
    }

    public function test_the_request_requires_a_token_and_a_device_name(): void
    {
        $this->fakeVerifier($this->account());

        $this->postJson('/api/v1/auth/google', [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['id_token', 'device_name']);
    }

    public function test_two_google_accounts_do_not_collide_on_username(): void
    {
        $this->fakeVerifier($this->account());
        $this->signIn()->assertOk();

        $this->fakeVerifier($this->account([
            'subject' => '104730',
            'email' => 'newcomer@googlemail.com',
        ]));
        $this->signIn()->assertJsonPath('user.handle', 'newcomer2');
    }

    public function test_the_google_avatar_is_kept(): void
    {
        $this->fakeVerifier($this->account());

        $this->signIn()->assertJsonPath(
            'user.google_avatar',
            'https://lh3.googleusercontent.com/a/photo',
        );
    }
}
