<?php

namespace Tests\Feature\Api;

use App\Models\Friendship;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FriendTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_profile_reports_where_the_viewer_stands(): void
    {
        $viewer = User::factory()->create();
        $other = User::factory()->create();

        $this->getJson("/api/v1/members/{$other->id}")
            ->assertOk()
            ->assertJsonPath('data.friendship', 'none');

        Sanctum::actingAs($viewer);

        $this->getJson("/api/v1/members/{$other->id}")
            ->assertOk()
            ->assertJsonPath('data.friendship', 'none');

        $this->getJson("/api/v1/members/{$viewer->id}")
            ->assertOk()
            ->assertJsonPath('data.friendship', 'self');
    }

    public function test_a_request_reads_as_requested_to_one_side_and_pending_to_the_other(): void
    {
        $asker = User::factory()->create();
        $asked = User::factory()->create();

        Sanctum::actingAs($asker);
        $this->postJson("/api/v1/members/{$asked->id}/friend")
            ->assertOk()
            ->assertJsonPath('friendship', 'requested');

        Sanctum::actingAs($asked);
        $this->getJson("/api/v1/members/{$asker->id}")
            ->assertOk()
            ->assertJsonPath('data.friendship', 'pending');
    }

    public function test_accepting_makes_it_mutual(): void
    {
        $asker = User::factory()->create();
        $asked = User::factory()->create();

        Sanctum::actingAs($asker);
        $this->postJson("/api/v1/members/{$asked->id}/friend")->assertOk();

        Sanctum::actingAs($asked);
        $this->postJson("/api/v1/members/{$asker->id}/friend/accept")
            ->assertOk()
            ->assertJsonPath('friendship', 'friends');

        $this->getJson("/api/v1/members/{$asker->id}")
            ->assertJsonPath('data.friendship', 'friends');

        Sanctum::actingAs($asker);
        $this->getJson("/api/v1/members/{$asked->id}")
            ->assertJsonPath('data.friendship', 'friends');
    }

    public function test_asking_somebody_who_already_asked_accepts_instead_of_opening_a_second_request(): void
    {
        $first = User::factory()->create();
        $second = User::factory()->create();

        Sanctum::actingAs($first);
        $this->postJson("/api/v1/members/{$second->id}/friend")->assertOk();

        // Both tapped the same button; neither should be left waiting.
        Sanctum::actingAs($second);
        $this->postJson("/api/v1/members/{$first->id}/friend")
            ->assertOk()
            ->assertJsonPath('friendship', 'friends');

        $this->assertSame(1, Friendship::count());
    }

    public function test_the_pair_is_only_ever_one_row(): void
    {
        $asker = User::factory()->create();
        $asked = User::factory()->create();

        Sanctum::actingAs($asker);
        $this->postJson("/api/v1/members/{$asked->id}/friend")->assertOk();
        $this->postJson("/api/v1/members/{$asked->id}/friend")
            ->assertOk()
            ->assertJsonPath('friendship', 'requested');

        $this->assertSame(1, Friendship::count());
    }

    public function test_one_call_withdraws_declines_and_unfriends(): void
    {
        $asker = User::factory()->create();
        $asked = User::factory()->create();

        // Withdrawn by the member who asked.
        Sanctum::actingAs($asker);
        $this->postJson("/api/v1/members/{$asked->id}/friend")->assertOk();
        $this->deleteJson("/api/v1/members/{$asked->id}/friend")
            ->assertOk()
            ->assertJsonPath('friendship', 'none');
        $this->assertSame(0, Friendship::count());

        // Declined by the member who was asked.
        $this->postJson("/api/v1/members/{$asked->id}/friend")->assertOk();
        Sanctum::actingAs($asked);
        $this->deleteJson("/api/v1/members/{$asker->id}/friend")
            ->assertOk()
            ->assertJsonPath('friendship', 'none');
        $this->assertSame(0, Friendship::count());

        // Unfriended once accepted.
        Sanctum::actingAs($asker);
        $this->postJson("/api/v1/members/{$asked->id}/friend")->assertOk();
        Sanctum::actingAs($asked);
        $this->postJson("/api/v1/members/{$asker->id}/friend/accept")->assertOk();
        $this->deleteJson("/api/v1/members/{$asker->id}/friend")
            ->assertOk()
            ->assertJsonPath('friendship', 'none');
        $this->assertSame(0, Friendship::count());
    }

    public function test_the_inbox_lists_only_requests_waiting_on_you(): void
    {
        $viewer = User::factory()->create();
        $asker = User::factory()->create(['name' => 'Asked me']);
        $asked = User::factory()->create();

        Sanctum::actingAs($asker);
        $this->postJson("/api/v1/members/{$viewer->id}/friend")->assertOk();

        // One the viewer sent, which is waiting on somebody else.
        Sanctum::actingAs($viewer);
        $this->postJson("/api/v1/members/{$asked->id}/friend")->assertOk();

        $this->getJson('/api/v1/friend-requests')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Asked me')
            ->assertJsonPath('data.0.friendship', 'pending');
    }

    public function test_an_accepted_request_leaves_the_inbox(): void
    {
        $viewer = User::factory()->create();
        $asker = User::factory()->create();

        Sanctum::actingAs($asker);
        $this->postJson("/api/v1/members/{$viewer->id}/friend")->assertOk();

        Sanctum::actingAs($viewer);
        $this->postJson("/api/v1/members/{$asker->id}/friend/accept")->assertOk();

        $this->getJson('/api/v1/friend-requests')
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_accepting_a_request_that_was_never_sent_is_a_404(): void
    {
        $viewer = User::factory()->create();
        $other = User::factory()->create();

        Sanctum::actingAs($viewer);
        $this->postJson("/api/v1/members/{$other->id}/friend/accept")
            ->assertNotFound();
    }

    public function test_you_cannot_befriend_yourself(): void
    {
        $viewer = User::factory()->create();

        Sanctum::actingAs($viewer);
        $this->postJson("/api/v1/members/{$viewer->id}/friend")
            ->assertStatus(422);
    }

    public function test_friend_calls_need_a_token(): void
    {
        $other = User::factory()->create();

        $this->postJson("/api/v1/members/{$other->id}/friend")->assertUnauthorized();
        $this->deleteJson("/api/v1/members/{$other->id}/friend")->assertUnauthorized();
        $this->getJson('/api/v1/friend-requests')->assertUnauthorized();
    }

    public function test_the_member_list_answers_the_state_without_a_query_per_member(): void
    {
        $viewer = User::factory()->create();
        $friend = User::factory()->create(['name' => 'Aaa Friend', 'playing' => null]);
        $stranger = User::factory()->create(['name' => 'Bbb Stranger', 'playing' => null]);

        Sanctum::actingAs($viewer);
        $this->postJson("/api/v1/members/{$friend->id}/friend")->assertOk();

        $queries = 0;
        DB::listen(function () use (&$queries) {
            $queries++;
        });

        $response = $this->getJson('/api/v1/members')->assertOk();

        $states = collect($response->json('data'))
            ->pluck('friendship', 'name');

        // The member list plus the two constrained friendship loads. Reading
        // the state per member would grow this with the strip.
        $this->assertLessThanOrEqual(5, $queries);

        $this->assertSame('requested', $states['Aaa Friend']);
        $this->assertSame('none', $states['Bbb Stranger']);
        $this->assertSame('self', $states[$viewer->name]);
    }

    public function test_the_feed_can_be_asked_for_one_members_posts(): void
    {
        $author = User::factory()->create();
        $other = User::factory()->create();

        Post::factory()->for($author, 'author')->create(['body' => 'Mine']);
        Post::factory()->for($other, 'author')->create(['body' => 'Theirs']);

        $this->getJson("/api/v1/feed?user={$author->id}")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.body', 'Mine');
    }

    public function test_a_members_posts_still_report_the_viewers_like(): void
    {
        $viewer = User::factory()->create();
        $author = User::factory()->create();
        $post = Post::factory()->for($author, 'author')->create();

        Sanctum::actingAs($viewer);
        $this->postJson("/api/v1/feed/{$post->id}/like")->assertOk();

        $this->getJson("/api/v1/feed?user={$author->id}")
            ->assertOk()
            ->assertJsonPath('data.0.liked_by_me', true)
            ->assertJsonPath('data.0.likes', 1);
    }
}
