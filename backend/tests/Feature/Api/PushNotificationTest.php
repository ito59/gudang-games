<?php

namespace Tests\Feature\Api;

use App\Models\Conversation;
use App\Models\Post;
use App\Models\User;
use App\Services\Push\Push;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Support\RecordingPush;
use Tests\TestCase;

class PushNotificationTest extends TestCase
{
    use RefreshDatabase;

    private RecordingPush $push;

    protected function setUp(): void
    {
        parent::setUp();
        $this->push = new RecordingPush;
        $this->app->instance(Push::class, $this->push);
    }

    public function test_notifications_are_on_for_a_new_account(): void
    {
        // Somebody who installs a chat app expects to be told when they are
        // written to; turning it off is a choice, not a discovery.
        Sanctum::actingAs(User::factory()->create());
        $this->getJson('/api/v1/me/notifications')
            ->assertOk()
            ->assertJsonPath('data.chat', true)
            ->assertJsonPath('data.news', true);
    }

    public function test_a_member_can_turn_each_one_off(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->patchJson('/api/v1/me/notifications', ['chat' => false])
            ->assertOk()
            ->assertJsonPath('data.chat', false)
            // Untouched, not reset.
            ->assertJsonPath('data.news', true);

        $this->assertFalse($user->fresh()->notify_chat);
        $this->assertTrue($user->fresh()->notify_news);
    }

    public function test_a_message_reaches_the_other_seat(): void
    {
        [$me, $them] = [User::factory()->create(), User::factory()->create()];
        $conversation = Conversation::between($me, $them);

        Sanctum::actingAs($me);
        $this->postJson("/api/v1/conversations/{$conversation->id}/messages", [
            'body' => 'Are you on later?',
        ])->assertCreated();

        $this->assertSame(["user:{$them->id}"], $this->push->targets());
        $this->assertSame($me->name, $this->push->sent[0]['message']->title);
        $this->assertSame('Are you on later?', $this->push->sent[0]['message']->body);
        $this->assertSame('chat', $this->push->sent[0]['message']->data['type']);
    }

    public function test_the_sender_is_not_notified_of_their_own_message(): void
    {
        [$me, $them] = [User::factory()->create(), User::factory()->create()];
        $conversation = Conversation::between($me, $them);

        Sanctum::actingAs($me);
        $this->postJson("/api/v1/conversations/{$conversation->id}/messages", ['body' => 'Hi']);

        $this->assertNotContains("user:{$me->id}", $this->push->targets());
    }

    public function test_somebody_who_turned_chat_off_is_left_alone(): void
    {
        $me = User::factory()->create();
        $them = User::factory()->create(['notify_chat' => false]);
        $conversation = Conversation::between($me, $them);

        Sanctum::actingAs($me);
        $this->postJson("/api/v1/conversations/{$conversation->id}/messages", ['body' => 'Hi'])
            ->assertCreated();

        // The message is still sent and stored — only the phone stays quiet.
        $this->assertSame([], $this->push->targets());
        $this->assertSame(1, $conversation->messages()->count());
    }

    public function test_publishing_news_tells_everybody_once(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin)->post('/admin/posts', [
            'kind' => 'news',
            'title' => 'Season 2 lands next week',
            'body' => 'Ranked resets on Monday.',
            'is_published' => true,
        ])->assertRedirect();

        $this->assertSame(['topic:news'], $this->push->targets());
        $this->assertSame(
            'Season 2 lands next week',
            $this->push->sent[0]['message']->title,
        );
    }

    public function test_editing_an_article_does_not_announce_it_again(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $post = Post::factory()->news()->for($admin, 'author')->create([
            'is_published' => true,
        ]);

        $this->actingAs($admin)->put("/admin/posts/{$post->id}", [
            'kind' => 'news',
            'title' => $post->title,
            'body' => 'Fixed a typo.',
            'is_published' => true,
        ])->assertRedirect();

        // Fixing a typo must not buzz everybody a second time.
        $this->assertSame([], $this->push->targets());
    }

    public function test_a_draft_announces_nothing_until_it_is_published(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin)->post('/admin/posts', [
            'kind' => 'news',
            'title' => 'Not yet',
            'body' => 'Draft.',
            'is_published' => false,
        ])->assertRedirect();

        $this->assertSame([], $this->push->targets());

        // Publishing it from the list is when it goes out.
        $post = Post::where('title', 'Not yet')->firstOrFail();
        $this->actingAs($admin)->patch("/admin/posts/{$post->id}/toggle");

        $this->assertSame(['topic:news'], $this->push->targets());
    }

    public function test_an_ordinary_post_announces_nothing(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin)->post('/admin/posts', [
            'kind' => 'update',
            'body' => 'Just a post.',
            'is_published' => true,
        ])->assertRedirect();

        $this->assertSame([], $this->push->targets());
    }
}
