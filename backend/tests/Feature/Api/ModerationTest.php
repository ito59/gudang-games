<?php

namespace Tests\Feature\Api;

use App\Events\MessageSent;
use App\Models\Message;
use App\Models\ModerationEvent;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ModerationTest extends TestCase
{
    use RefreshDatabase;

    private function thread(): array
    {
        [$viewer, $other] = [User::factory()->create(), User::factory()->create()];
        Sanctum::actingAs($viewer);

        $id = $this->postJson('/api/v1/conversations', ['user_id' => $other->id])
            ->json('data.id');

        return [$viewer, $other, $id];
    }

    private function say(int $thread, string $body)
    {
        return $this->postJson("/api/v1/conversations/$thread/messages", ['body' => $body]);
    }

    public function test_a_clean_message_goes_through(): void
    {
        [, , $thread] = $this->thread();

        $this->say($thread, 'good game, well played')->assertCreated();
    }

    public function test_profanity_is_refused_and_never_stored(): void
    {
        Event::fake([MessageSent::class]);
        [, , $thread] = $this->thread();

        $this->say($thread, 'kontol lu semua')
            ->assertStatus(422)
            ->assertJsonValidationErrors('body');

        $this->assertDatabaseCount('messages', 0);
        Event::assertNotDispatched(MessageSent::class);
    }

    /**
     * The whole point of normalising: one list entry has to cover every way
     * somebody writes the same word.
     */
    public function test_the_usual_ways_around_a_word_list_are_covered(): void
    {
        [, , $thread] = $this->thread();

        foreach ([
            'leetspeak' => 'k0nt0l',
            'stretched' => 'koooontooool',
            'punctuated' => 'k.o.n.t.o.l',
            'spelt out' => 'k o n t o l',
            'capitals' => 'KONTOL',
            'mid sentence' => 'dasar Kontol!',
        ] as $label => $attempt) {
            $this->say($thread, $attempt)
                ->assertStatus(422, "$label should have been refused");
        }
    }

    /**
     * The failure a word list makes most often. `bangsa tercinta` contains
     * `bangsat` once the spaces come out, and `class` contains `ass`.
     */
    public function test_innocent_words_are_not_mistaken_for_abuse(): void
    {
        [, , $thread] = $this->thread();

        foreach ([
            'bangsa tercinta',
            'welcome to class everyone',
            'masa sih, kok bisa',
            'my asus laptop runs it fine',
            'anak asuh saya main juga',
        ] as $innocent) {
            $this->say($thread, $innocent)
                ->assertCreated("'$innocent' should have been allowed");
        }
    }

    public function test_a_refusal_is_logged_for_review(): void
    {
        [$viewer, , $thread] = $this->thread();

        $this->say($thread, 'memek banget lu');

        $event = ModerationEvent::sole();

        $this->assertSame($viewer->id, $event->user_id);
        $this->assertSame('chat', $event->context);
        $this->assertSame('profanity', $event->reason);
        // Kept whole, so an admin can see what the filter actually saw.
        $this->assertSame('memek banget lu', $event->body);
    }

    public function test_the_same_line_twice_is_refused(): void
    {
        [, , $thread] = $this->thread();

        $this->say($thread, 'anyone up for a match')->assertCreated();
        $this->say($thread, 'anyone up for a match')->assertStatus(422);
        // Punctuation is not a different line.
        $this->say($thread, 'Anyone up for a match!!!')->assertStatus(422);
        $this->say($thread, 'anyone up for two matches')->assertCreated();
    }

    public function test_a_burst_is_refused(): void
    {
        [, , $thread] = $this->thread();

        $limit = config('moderation.spam.burst.limit');

        for ($i = 0; $i < $limit; $i++) {
            $this->say($thread, "message number $i")->assertCreated();
        }

        $this->say($thread, 'one too many')->assertStatus(422);
    }

    public function test_link_spam_shouting_and_key_mashing_are_refused(): void
    {
        [, , $thread] = $this->thread();

        $this->say($thread, 'free skins http://a.com http://b.com http://c.com')
            ->assertStatus(422);
        $this->say($thread, 'BUY MY ACCOUNT RIGHT NOW PLEASE')
            ->assertStatus(422);
        $this->say($thread, 'aaaaaaaaaaaaaaaaaaaaaa')
            ->assertStatus(422);
    }

    /** Two links is somebody sharing a clip and where it came from. */
    public function test_a_couple_of_links_are_fine(): void
    {
        [, , $thread] = $this->thread();

        $this->say($thread, 'clip http://a.com and the source http://b.com')
            ->assertCreated();
    }

    /**
     * Each place a member can write is counted separately, so a long
     * conversation never uses up somebody's allowance for posting.
     */
    public function test_chat_and_posts_have_separate_allowances(): void
    {
        [$viewer, , $thread] = $this->thread();

        $limit = config('moderation.spam.burst.limit');

        for ($i = 0; $i < $limit; $i++) {
            $this->say($thread, "chatter number $i")->assertCreated();
        }

        Sanctum::actingAs($viewer);
        $this->postJson('/api/v1/feed', ['body' => 'first post of the day', 'kind' => 'clip'])
            ->assertCreated();
    }

    public function test_posts_and_comments_are_filtered_too(): void
    {
        $author = User::factory()->create();
        Sanctum::actingAs($author);

        $this->postJson('/api/v1/feed', ['body' => 'ngentot semua', 'kind' => 'clip'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('body');

        $post = Post::factory()->create();

        $this->postJson("/api/v1/feed/{$post->id}/comments", ['body' => 'goblok banget'])
            ->assertStatus(422);

        $this->assertDatabaseCount('posts', 1);
        $this->assertDatabaseCount('comments', 0);
        $this->assertSame(['post', 'comment'], ModerationEvent::pluck('context')->all());
    }

    public function test_turning_the_filter_off_lets_everything_through(): void
    {
        config(['moderation.enabled' => false]);

        [, , $thread] = $this->thread();

        $this->say($thread, 'kontol')->assertCreated();
        $this->assertSame(1, Message::count());
        $this->assertDatabaseCount('moderation_events', 0);
    }

    public function test_the_sender_is_not_told_which_word_tripped_it(): void
    {
        [, , $thread] = $this->thread();

        $response = $this->say($thread, 'dasar kontol');

        // Naming the word teaches the way around it.
        $this->assertStringNotContainsStringIgnoringCase('kontol', $response->json('message'));
    }

    /** The filter is behind the token, not in front of it. */
    public function test_a_thread_still_needs_a_token(): void
    {
        $this->postJson('/api/v1/conversations/1/messages', ['body' => 'kontol'])
            ->assertUnauthorized();

        $this->assertDatabaseCount('moderation_events', 0);
    }
}
