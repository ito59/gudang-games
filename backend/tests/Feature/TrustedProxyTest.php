<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * TLS is terminated by a proxy in production, so the app only learns the
 * request was secure from `X-Forwarded-Proto`.
 *
 * This is guarded because getting it wrong is silent and looks like
 * something else entirely: login succeeds, redirects to `http://`, the
 * browser never arrives, and the person is handed the login page again as
 * if their password were wrong.
 */
class TrustedProxyTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_forwarded_request_is_seen_as_secure(): void
    {
        $this->withServerVariables(['REMOTE_ADDR' => '127.0.0.1'])
            ->withHeaders(['X-Forwarded-Proto' => 'https'])
            ->get('/login')
            ->assertOk();

        $this->assertTrue(request()->isSecure());
        $this->assertStringStartsWith('https://', url('/dashboard'));
    }

    public function test_an_untrusted_address_cannot_forge_the_scheme(): void
    {
        // Anything outside loopback and the private ranges is a stranger, and
        // a stranger's forwarding headers are not evidence of anything.
        $this->withServerVariables(['REMOTE_ADDR' => '203.0.113.9'])
            ->withHeaders(['X-Forwarded-Proto' => 'https'])
            ->get('/login')
            ->assertOk();

        $this->assertFalse(request()->isSecure());
    }
}
