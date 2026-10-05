<?php

namespace Tests\Feature\Api;

use App\Models\Block;
use App\Models\Comment;
use App\Models\Conversation;
use App\Models\Friendship;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BlockTest extends TestCase
{
    use RefreshDatabase;

    private function block(User $viewer, User $other)
    {
        Sanctum::actingAs($viewer);

        return $this->postJson("/api/v1/members/{$other->id}/block");
    }

    public function test_blocking_is_recorded_once_however_often_it_is_tapped(): void
    {
        [$viewer, $other] = User::factory()->count(2)->create();

        $this->block($viewer, $other)->assertOk()->assertJson(['blocked' => true]);
        $this->block($viewer, $other)->assertOk();

        $this->assertSame(1, Block::count());
    }

    public function test_you_cannot_block_yourself(): void
    {
        $viewer = User::factory()->create();

        $this->block($viewer, $viewer)->assertStatus(422);
        $this->assertSame(0, Block::count());
    }

    public function test_their_posts_and_comments_leave_the_feed_both_ways(): void
    {
        [$viewer, $other] = User::factory()->count(2)->create();
        $theirs = Post::factory()->for($other, 'author')->create();
        $mine = Post::factory()->for($viewer, 'author')->create();
        Comment::create(['post_id' => $mine->id, 'user_id' => $other->id, 'body' => 'a reply']);

        $this->block($viewer, $other);

        $feed = $this->getJson('/api/v1/feed')->assertOk();
        $this->assertSame([$mine->id], collect($feed->json('data'))->pluck('id')->all());

        $this->getJson("/api/v1/feed/{$mine->id}/comments")
            ->assertOk()
            ->assertJsonCount(0, 'data');

        // And from the other side, without them being told why.
        Sanctum::actingAs($other);
        $feed = $this->getJson('/api/v1/feed')->assertOk();
        $this->assertSame([$theirs->id], collect($feed->json('data'))->pluck('id')->all());
    }

    public function test_a_blocked_member_leaves_the_online_strip(): void
    {
        [$viewer, $other] = User::factory()->count(2)->create(['playing' => 'Star Wars']);

        $this->block($viewer, $other);

        $ids = collect($this->getJson('/api/v1/members')->json('data'))->pluck('id');

        $this->assertFalse($ids->contains($other->id));
        $this->assertTrue($ids->contains($viewer->id));
    }

    /** The profile stays reachable: it is where the block is undone. */
    public function test_their_profile_still_opens_and_says_it_is_blocked(): void
    {
        [$viewer, $other] = User::factory()->count(2)->create();

        $this->block($viewer, $other);

        $this->getJson("/api/v1/members/{$other->id}")
            ->assertOk()
            ->assertJsonPath('data.blocked', true);
    }

    /**
     * Being blocked *by* somebody is their business, not something the app
     * hands over — so the other side's view says nothing.
     */
    public function test_the_blocked_member_is_not_told(): void
    {
        [$viewer, $other] = User::factory()->count(2)->create();

        $this->block($viewer, $other);

        Sanctum::actingAs($other);
        $this->getJson("/api/v1/members/{$viewer->id}")
            ->assertOk()
            ->assertJsonPath('data.blocked', false);
    }

    public function test_neither_of_them_can_open_or_write_the_thread(): void
    {
        [$viewer, $other] = User::factory()->count(2)->create();
        $conversation = Conversation::between($viewer, $other);
        $conversation->messages()->create(['user_id' => $other->id, 'body' => 'hello there']);

        $this->block($viewer, $other);

        $this->postJson("/api/v1/conversations/{$conversation->id}/messages", ['body' => 'hi'])
            ->assertForbidden();
        $this->postJson('/api/v1/conversations', ['user_id' => $other->id])
            ->assertForbidden();

        Sanctum::actingAs($other);
        $this->postJson("/api/v1/conversations/{$conversation->id}/messages", ['body' => 'are you there'])
            ->assertForbidden();
        $this->postJson('/api/v1/conversations', ['user_id' => $viewer->id])
            ->assertForbidden();

        $this->assertSame(1, $conversation->messages()->count());
    }

    public function test_the_thread_leaves_both_conversation_lists(): void
    {
        [$viewer, $other, $third] = User::factory()->count(3)->create();
        Conversation::between($viewer, $other)->update(['last_message_at' => now()]);
        $kept = Conversation::between($viewer, $third);
        $kept->update(['last_message_at' => now()]);

        $this->block($viewer, $other);

        $ids = collect($this->getJson('/api/v1/conversations')->json('data'))->pluck('id');
        $this->assertSame([$kept->id], $ids->all());

        Sanctum::actingAs($other);
        $this->getJson('/api/v1/conversations')->assertOk()->assertJsonCount(0, 'data');
    }

    /** Nothing was deleted, so unblocking brings the thread back. */
    public function test_unblocking_restores_reach(): void
    {
        [$viewer, $other] = User::factory()->count(2)->create();
        $conversation = Conversation::between($viewer, $other);

        $this->block($viewer, $other);
        $this->deleteJson("/api/v1/members/{$other->id}/block")
            ->assertOk()
            ->assertJson(['blocked' => false]);

        $this->postJson("/api/v1/conversations/{$conversation->id}/messages", ['body' => 'back again'])
            ->assertCreated();
        $this->getJson('/api/v1/conversations')->assertJsonCount(1, 'data');
    }

    /** Leaving somebody on a friends list they cannot reach is worse. */
    public function test_blocking_ends_the_friendship(): void
    {
        [$viewer, $other] = User::factory()->count(2)->create();
        Friendship::create([
            'user_id' => $viewer->id,
            'friend_id' => $other->id,
            'accepted_at' => now(),
        ]);

        $this->block($viewer, $other);

        $this->assertSame(0, Friendship::count());
        $this->getJson("/api/v1/members/{$other->id}")
            ->assertJsonPath('data.friendship', 'none');
    }

    public function test_the_blocked_list_is_the_members_own(): void
    {
        [$viewer, $other] = User::factory()->count(2)->create();

        $this->block($viewer, $other);

        $this->getJson('/api/v1/me/blocks')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $other->id);

        Sanctum::actingAs($other);
        $this->getJson('/api/v1/me/blocks')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_blocking_needs_a_token(): void
    {
        $other = User::factory()->create();

        $this->postJson("/api/v1/members/{$other->id}/block")->assertUnauthorized();
        $this->getJson('/api/v1/me/blocks')->assertUnauthorized();
    }
}
