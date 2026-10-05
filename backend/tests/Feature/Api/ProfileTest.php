<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfileTest extends TestCase
{
    use RefreshDatabase;

    private function member(array $overrides = []): User
    {
        return User::factory()->create($overrides + [
            'name' => 'Rey Anandra',
            'username' => 'neonrey',
            'bio' => 'Night-shift raider.',
            'location' => 'Jakarta, ID',
        ]);
    }

    private function edit(array $data)
    {
        return $this->patchJson('/api/v1/me', $data);
    }

    public function test_it_returns_the_signed_in_member(): void
    {
        Sanctum::actingAs($this->member());

        $this->getJson('/api/v1/me')
            ->assertOk()
            ->assertJsonPath('data.name', 'Rey Anandra')
            ->assertJsonPath('data.handle', 'neonrey')
            ->assertJsonPath('data.bio', 'Night-shift raider.')
            ->assertJsonPath('data.location', 'Jakarta, ID');
    }

    public function test_a_member_can_update_their_own_profile(): void
    {
        $user = $this->member();
        Sanctum::actingAs($user);

        $this->edit([
            'name' => 'Rey A.',
            'username' => 'reya',
            'bio' => 'Back on ranked.',
            'location' => 'Bandung, ID',
        ])
            ->assertOk()
            ->assertJsonPath('data.name', 'Rey A.')
            ->assertJsonPath('data.handle', 'reya');

        $user->refresh();
        $this->assertSame('reya', $user->username);
        $this->assertSame('Back on ranked.', $user->bio);
        $this->assertSame('Bandung, ID', $user->location);
    }

    public function test_clearing_bio_and_location_stores_empty_strings(): void
    {
        $user = $this->member();
        Sanctum::actingAs($user);

        // The app sends null for a field the person emptied.
        $this->edit([
            'name' => 'Rey Anandra',
            'username' => 'neonrey',
            'bio' => null,
            'location' => null,
        ])->assertOk();

        $user->refresh();
        $this->assertSame('', $user->bio);
        $this->assertSame('', $user->location);
    }

    public function test_a_username_already_taken_is_refused(): void
    {
        $this->member(['username' => 'takenone', 'email' => 'other@test.dev']);
        Sanctum::actingAs($this->member(['email' => 'me@test.dev']));

        $this->edit([
            'name' => 'Rey Anandra',
            'username' => 'takenone',
            'bio' => '',
            'location' => '',
        ])
            ->assertStatus(422)
            ->assertJsonPath('errors.username.0', 'That username is taken.');
    }

    public function test_keeping_your_own_username_is_not_a_collision(): void
    {
        $user = $this->member();
        Sanctum::actingAs($user);

        // Editing only the bio must not trip the uniqueness rule on yourself.
        $this->edit([
            'name' => 'Rey Anandra',
            'username' => 'neonrey',
            'bio' => 'Changed.',
            'location' => 'Jakarta, ID',
        ])->assertOk();

        $this->assertSame('Changed.', $user->fresh()->bio);
    }

    public function test_a_username_with_punctuation_is_refused(): void
    {
        Sanctum::actingAs($this->member());

        $this->edit([
            'name' => 'Rey Anandra',
            'username' => 'rey anandra!',
            'bio' => '',
            'location' => '',
        ])
            ->assertStatus(422)
            ->assertJsonPath(
                'errors.username.0',
                'A username can only use letters, numbers and underscores.',
            );
    }

    public function test_name_and_username_are_required(): void
    {
        Sanctum::actingAs($this->member());

        $this->edit(['bio' => 'x'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'username']);
    }

    public function test_over_long_values_are_refused(): void
    {
        Sanctum::actingAs($this->member());

        $this->edit([
            'name' => str_repeat('a', 121),
            'username' => 'neonrey',
            'bio' => str_repeat('b', 281),
            'location' => str_repeat('c', 121),
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'bio', 'location']);
    }

    public function test_a_signed_out_request_cannot_read_or_write_a_profile(): void
    {
        $this->getJson('/api/v1/me')->assertStatus(401);
        $this->edit(['name' => 'x', 'username' => 'y'])->assertStatus(401);
    }

    public function test_the_endpoint_cannot_be_used_to_change_privileged_fields(): void
    {
        $user = $this->member(['is_admin' => false, 'games_owned' => 3]);
        Sanctum::actingAs($user);

        $this->edit([
            'name' => 'Rey Anandra',
            'username' => 'neonrey',
            'is_admin' => true,
            'games_owned' => 999,
            'email' => 'attacker@test.dev',
        ])->assertOk();

        $user->refresh();
        $this->assertFalse($user->is_admin);
        $this->assertSame(3, $user->games_owned);
        $this->assertNotSame('attacker@test.dev', $user->email);
    }
}
