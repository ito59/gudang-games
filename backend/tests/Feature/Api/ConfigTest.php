<?php

namespace Tests\Feature\Api;

use App\Services\Google\ClientIds;
use Tests\TestCase;

class ConfigTest extends TestCase
{
    public function test_it_reports_google_as_off_when_nothing_is_configured(): void
    {
        config([
            'services.google.client_ids' => [],
            'services.google.server_client_id' => null,
            'services.google.ios_client_id' => null,
        ]);

        $this->getJson('/api/v1/config')
            ->assertOk()
            ->assertJsonPath('google.enabled', false)
            ->assertJsonPath('google.server_client_id', null);
    }

    public function test_it_hands_the_app_the_web_client_id(): void
    {
        config([
            'services.google.client_ids' => ['web.apps.googleusercontent.com'],
            'services.google.server_client_id' => 'web.apps.googleusercontent.com',
            'services.google.ios_client_id' => 'ios.apps.googleusercontent.com',
        ]);

        // Configuring the server is what turns the button on in the app.
        $this->getJson('/api/v1/config')
            ->assertOk()
            ->assertJsonPath('google.enabled', true)
            ->assertJsonPath('google.server_client_id', 'web.apps.googleusercontent.com')
            ->assertJsonPath('google.ios_client_id', 'ios.apps.googleusercontent.com');
    }

    public function test_it_is_readable_without_signing_in(): void
    {
        // The app needs this before anybody has an account.
        $this->getJson('/api/v1/config')->assertOk();
    }

    public function test_the_accepted_audiences_default_to_the_configured_clients(): void
    {
        $this->assertSame(
            ['web.apps.googleusercontent.com', 'ios.apps.googleusercontent.com'],
            ClientIds::accepted(null, 'web.apps.googleusercontent.com', 'ios.apps.googleusercontent.com'),
        );
    }

    public function test_an_explicit_list_replaces_the_defaults(): void
    {
        $this->assertSame(
            ['one.apps.googleusercontent.com', 'two.apps.googleusercontent.com'],
            ClientIds::accepted(
                ' one.apps.googleusercontent.com , two.apps.googleusercontent.com ',
                'web.apps.googleusercontent.com',
                null,
            ),
        );
    }

    public function test_nothing_configured_accepts_nothing(): void
    {
        // An empty list disables sign-in; it must never mean "allow any".
        $this->assertSame([], ClientIds::accepted(null, null, null));
        $this->assertSame([], ClientIds::accepted('', '', ''));
    }

    public function test_the_same_client_twice_is_listed_once(): void
    {
        $this->assertSame(
            ['web.apps.googleusercontent.com'],
            ClientIds::accepted(null, 'web.apps.googleusercontent.com', 'web.apps.googleusercontent.com'),
        );
    }
}
