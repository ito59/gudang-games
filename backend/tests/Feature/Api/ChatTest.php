<?php

namespace Tests\Feature\Api;

use App\Events\MessageSent;
use App\Events\ThreadRead;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Laravel\Sanctum\Sanctum;
use RuntimeException;
use Tests\TestCase;

class ChatTest extends TestCase
{
    use RefreshDatabase;

    private function pair(): array
    {
        return [User::factory()->create(), User::factory()->create()];
    }

    /** Opens the thread and returns its id. */
    private function open(User $viewer, User $other): int
    {
        Sanctum::actingAs($viewer);

        return $this->postJson('/api/v1/conversations', ['user_id' => $other->id])
            ->assertSuccessful()
            ->json('data.id');
    }

    public function test_messaging_somebody_opens_a_thread_with_them(): void
    {
        [$me, $them] = $this->pair();
        Sanctum::actingAs($me);

        $this->postJson('/api/v1/conversations', ['user_id' => $them->id])
            ->assertCreated()
            ->assertJsonPath('data.with.id', $them->id)
            ->assertJsonPath('data.with.name', $them->name)
            ->assertJsonPath('data.last_message', null)
            ->assertJsonPath('data.unread', 0);
    }

    public function test_a_pair_only_ever_has_one_thread(): void
    {
        [$me, $them] = $this->pair();

        $first = $this->open($me, $them);

        // Again from this side, then from theirs.
        Sanctum::actingAs($me);
        $this->postJson('/api/v1/conversations', ['user_id' => $them->id])
            ->assertOk()
            ->assertJsonPath('data.id', $first);

        Sanctum::actingAs($them);
        $this->postJson('/api/v1/conversations', ['user_id' => $me->id])
            ->assertOk()
            ->assertJsonPath('data.id', $first);

        $this->assertSame(1, Conversation::count());
    }

    public function test_you_cannot_message_yourself(): void
    {
        $me = User::factory()->create();
        Sanctum::actingAs($me);

        $this->postJson('/api/v1/conversations', ['user_id' => $me->id])
            ->assertStatus(422);
    }

    public function test_a_message_is_stored_and_read_back_in_order(): void
    {
        [$me, $them] = $this->pair();
        $id = $this->open($me, $them);

        Sanctum::actingAs($me);
        $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => 'First'])
            ->assertCreated()
            ->assertJsonPath('data.body', 'First')
            ->assertJsonPath('data.author.id', $me->id);

        Sanctum::actingAs($them);
        $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => 'Second'])
            ->assertCreated();

        $this->getJson("/api/v1/conversations/{$id}/messages")
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.body', 'First')
            ->assertJsonPath('data.1.body', 'Second');
    }

    public function test_an_empty_message_is_rejected(): void
    {
        [$me, $them] = $this->pair();
        $id = $this->open($me, $them);

        Sanctum::actingAs($me);
        $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => ''])
            ->assertStatus(422)
            ->assertJsonValidationErrors('body');
    }

    public function test_sending_broadcasts_to_the_other_seat_only(): void
    {
        Event::fake([MessageSent::class]);

        [$me, $them] = $this->pair();
        $id = $this->open($me, $them);

        Sanctum::actingAs($me);
        $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => 'Hello'])
            ->assertCreated();

        Event::assertDispatched(MessageSent::class, function (MessageSent $event) use ($id) {
            $channels = $event->broadcastOn();

            return $event->message->conversation_id === $id
                && $channels[0]->name === "private-conversation.{$id}"
                && $event->broadcastAs() === 'message.sent'
                && $event->broadcastWith()['message']['body'] === 'Hello';
        });
    }

    public function test_a_silent_socket_does_not_lose_the_message(): void
    {
        [$me, $them] = $this->pair();
        $id = $this->open($me, $them);

        // Reverb being down must not turn a saved message into a failed send:
        // the sender would be told it never sent while the row sat in the
        // database, and the other side would find it on their next load.
        Event::listen(MessageSent::class, function () {
            throw new RuntimeException('reverb is down');
        });

        Sanctum::actingAs($me);
        $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => 'Still saved'])
            ->assertCreated()
            ->assertJsonPath('data.body', 'Still saved');

        $this->assertSame(1, Message::where('conversation_id', $id)->count());

        $this->getJson("/api/v1/conversations/{$id}/messages")
            ->assertOk()
            ->assertJsonPath('data.0.body', 'Still saved');
    }

    public function test_a_thread_you_are_not_in_is_closed_to_you(): void
    {
        [$me, $them] = $this->pair();
        $stranger = User::factory()->create();
        $id = $this->open($me, $them);

        Sanctum::actingAs($stranger);

        // A 403, not an empty list: an outsider learns nothing from a guess.
        $this->getJson("/api/v1/conversations/{$id}/messages")->assertForbidden();
        $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => 'Hi'])
            ->assertForbidden();
        $this->postJson("/api/v1/conversations/{$id}/read")->assertForbidden();
    }

    public function test_chat_needs_a_token(): void
    {
        $this->getJson('/api/v1/conversations')->assertUnauthorized();
        $this->postJson('/api/v1/conversations', ['user_id' => 1])->assertUnauthorized();
    }

    public function test_the_list_counts_what_the_viewer_has_not_read(): void
    {
        [$me, $them] = $this->pair();
        $id = $this->open($me, $them);

        Sanctum::actingAs($them);
        foreach (['One', 'Two', 'Three'] as $body) {
            $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => $body]);
        }

        Sanctum::actingAs($me);
        $this->getJson('/api/v1/conversations')
            ->assertOk()
            ->assertJsonPath('data.0.unread', 3)
            ->assertJsonPath('data.0.last_message.body', 'Three')
            ->assertJsonPath('data.0.last_message.mine', false);

        // Their own three are not unread to them.
        Sanctum::actingAs($them);
        $this->getJson('/api/v1/conversations')
            ->assertOk()
            ->assertJsonPath('data.0.unread', 0)
            ->assertJsonPath('data.0.last_message.mine', true);
    }

    public function test_reading_a_thread_clears_its_count(): void
    {
        [$me, $them] = $this->pair();
        $id = $this->open($me, $them);

        Sanctum::actingAs($them);
        $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => 'Seen soon']);

        Sanctum::actingAs($me);
        $this->getJson('/api/v1/conversations')->assertJsonPath('data.0.unread', 1);

        $this->postJson("/api/v1/conversations/{$id}/read")->assertOk();
        $this->getJson('/api/v1/conversations')->assertJsonPath('data.0.unread', 0);

        // Anything said after that is unread again.
        Sanctum::actingAs($them);
        $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => 'And another']);

        Sanctum::actingAs($me);
        $this->getJson('/api/v1/conversations')->assertJsonPath('data.0.unread', 1);
    }

    public function test_the_list_says_how_far_the_other_person_has_read(): void
    {
        [$me, $them] = $this->pair();
        $id = $this->open($me, $them);

        Sanctum::actingAs($me);
        $first = $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => 'One'])
            ->json('data.id');

        // Never opened: nothing of mine has landed yet.
        $this->getJson('/api/v1/conversations')
            ->assertJsonPath('data.0.their_last_read_id', null);

        Sanctum::actingAs($them);
        $this->postJson("/api/v1/conversations/{$id}/read")->assertOk();

        Sanctum::actingAs($me);
        $this->getJson('/api/v1/conversations')
            ->assertJsonPath('data.0.their_last_read_id', (int) $first);
    }

    public function test_a_message_sent_after_they_looked_away_is_not_read(): void
    {
        [$me, $them] = $this->pair();
        $id = $this->open($me, $them);

        Sanctum::actingAs($me);
        $seen = $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => 'Seen'])
            ->json('data.id');

        Sanctum::actingAs($them);
        $this->postJson("/api/v1/conversations/{$id}/read")->assertOk();

        Sanctum::actingAs($me);
        $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => 'Sent after']);

        // The pointer stays where they stopped, so the later message is
        // still only delivered — not read.
        $this->getJson('/api/v1/conversations')
            ->assertJsonPath('data.0.their_last_read_id', (int) $seen);
    }

    public function test_reading_tells_the_other_seat(): void
    {
        Event::fake([ThreadRead::class]);

        [$me, $them] = $this->pair();
        $id = $this->open($me, $them);

        Sanctum::actingAs($me);
        $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => 'One']);

        Sanctum::actingAs($them);
        $this->postJson("/api/v1/conversations/{$id}/read")->assertOk();

        Event::assertDispatched(ThreadRead::class, function (ThreadRead $event) use ($id, $them) {
            $payload = $event->broadcastWith();

            return $event->broadcastOn()[0]->name === "private-conversation.{$id}"
                && $event->broadcastAs() === 'thread.read'
                && $payload['reader_id'] === $them->id
                && $payload['last_read_message_id'] !== null;
        });
    }

    public function test_a_silent_socket_does_not_stop_a_read(): void
    {
        [$me, $them] = $this->pair();
        $id = $this->open($me, $them);

        Sanctum::actingAs($me);
        $this->postJson("/api/v1/conversations/{$id}/messages", ['body' => 'One']);

        Event::listen(ThreadRead::class, function () {
            throw new RuntimeException('reverb is down');
        });

        // Reverb being unreachable must not stop the thread being marked
        // read, any more than it stops a message being sent.
        Sanctum::actingAs($them);
        $this->postJson("/api/v1/conversations/{$id}/read")->assertOk();

        $this->getJson('/api/v1/conversations')->assertJsonPath('data.0.unread', 0);
    }

    public function test_threads_are_listed_by_who_spoke_last(): void
    {
        $me = User::factory()->create();
        $quiet = User::factory()->create(['name' => 'Quiet']);
        $recent = User::factory()->create(['name' => 'Recent']);

        $first = $this->open($me, $quiet);
        $second = $this->open($me, $recent);

        Sanctum::actingAs($me);
        $this->postJson("/api/v1/conversations/{$first}/messages", ['body' => 'Old news']);
        $this->travel(2)->minutes();
        $this->postJson("/api/v1/conversations/{$second}/messages", ['body' => 'Just now']);

        $this->getJson('/api/v1/conversations')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.with.name', 'Recent')
            ->assertJsonPath('data.1.with.name', 'Quiet');
    }

    public function test_somebody_elses_thread_is_not_in_your_list(): void
    {
        [$me, $them] = $this->pair();
        $strangers = $this->pair();

        $this->open($me, $them);
        $this->open($strangers[0], $strangers[1]);

        Sanctum::actingAs($me);
        $this->getJson('/api/v1/conversations')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.with.id', $them->id);
    }
}
