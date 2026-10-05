<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PresenceTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_member_nobody_has_heard_from_is_offline_whatever_they_were_playing(): void
    {
        $member = User::factory()->create(['playing' => 'Mystic Ruin', 'last_seen_at' => null]);

        $this->getJson("/api/v1/members/{$member->id}")
            ->assertJsonPath('data.is_online', false)
            ->assertJsonPath('data.playing', 'Mystic Ruin');
    }

    public function test_any_signed_in_request_counts_as_being_seen(): void
    {
        $member = User::factory()->create(['playing' => null, 'last_seen_at' => null]);
        Sanctum::actingAs($member);

        $this->getJson('/api/v1/me')->assertOk();

        $this->assertNotNull($member->fresh()->last_seen_at);
        $this->getJson("/api/v1/members/{$member->id}")->assertJsonPath('data.is_online', true);
    }

    public function test_the_heartbeat_keeps_a_member_online_and_the_window_lets_them_go(): void
    {
        $member = User::factory()->create(['last_seen_at' => null]);
        Sanctum::actingAs($member);

        $this->postJson('/api/v1/me/presence')->assertNoContent();
        $this->assertTrue($member->fresh()->isOnline());

        $this->travel(User::ONLINE_WINDOW_SECONDS + 1)->seconds();
        $this->assertFalse($member->fresh()->isOnline());
    }

    public function test_going_to_the_background_drops_off_at_once(): void
    {
        $member = User::factory()->create(['last_seen_at' => now()]);
        Sanctum::actingAs($member);

        $this->deleteJson('/api/v1/me/presence')->assertNoContent();

        $this->assertNull($member->fresh()->last_seen_at);
    }

    public function test_being_seen_does_not_touch_updated_at(): void
    {
        $member = User::factory()->create(['last_seen_at' => null, 'updated_at' => now()->subDay()]);
        $before = $member->updated_at->toDateTimeString();
        Sanctum::actingAs($member);

        $this->postJson('/api/v1/me/presence');

        $this->assertSame($before, $member->fresh()->updated_at->toDateTimeString());
    }

    public function test_online_members_lead_the_strip(): void
    {
        User::factory()->create(['name' => 'Aaa Away', 'last_seen_at' => null]);
        User::factory()->create(['name' => 'Zzz Here', 'last_seen_at' => now()]);

        $this->getJson('/api/v1/members')
            ->assertJsonPath('data.0.name', 'Zzz Here')
            ->assertJsonPath('data.0.is_online', true)
            ->assertJsonPath('data.1.is_online', false);
    }

    public function test_a_conversation_says_whether_the_other_person_is_online(): void
    {
        [$viewer, $other] = User::factory()->count(2)->create(['last_seen_at' => null]);
        $other->forceFill(['last_seen_at' => now()])->save();
        Sanctum::actingAs($viewer);

        $this->postJson('/api/v1/conversations', ['user_id' => $other->id])->assertSuccessful();

        $this->getJson('/api/v1/conversations')->assertJsonPath('data.0.with.is_online', true);
    }
}
