<?php

namespace Tests\Feature\Api;

use App\Models\Conversation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Who may listen to a thread's live messages.
 *
 * Its own class because of the setUp below: the rest of the suite runs on the
 * null broadcaster, and sending a message under a real one would try to reach
 * a Reverb server that is not running in tests.
 */
class ChatChannelTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        // `Broadcast::channel()` registers against whichever broadcaster is
        // default when the app boots, so this cannot be a `config()` call
        // inside a test — by then the channels are on the null driver.
        $_ENV['BROADCAST_CONNECTION'] = $_SERVER['BROADCAST_CONNECTION'] = 'reverb';

        parent::setUp();
    }

    protected function tearDown(): void
    {
        $_ENV['BROADCAST_CONNECTION'] = $_SERVER['BROADCAST_CONNECTION'] = 'null';

        parent::tearDown();
    }

    private function authorise(int $id): TestResponse
    {
        return $this->postJson('/api/broadcasting/auth', [
            'socket_id' => '123.456',
            'channel_name' => "private-conversation.{$id}",
        ]);
    }

    public function test_both_participants_may_listen(): void
    {
        $me = User::factory()->create();
        $them = User::factory()->create();
        $conversation = Conversation::between($me, $them);

        Sanctum::actingAs($me);
        $this->authorise($conversation->id)
            ->assertOk()
            ->assertJsonStructure(['auth']);

        Sanctum::actingAs($them);
        $this->authorise($conversation->id)->assertOk();
    }

    public function test_an_outsider_may_not(): void
    {
        $conversation = Conversation::between(
            User::factory()->create(),
            User::factory()->create(),
        );

        // Channel authorisation is the only thing between a signed-in member
        // and somebody else's live messages.
        Sanctum::actingAs(User::factory()->create());
        $this->authorise($conversation->id)->assertForbidden();
    }

    public function test_listening_needs_a_token(): void
    {
        $conversation = Conversation::between(
            User::factory()->create(),
            User::factory()->create(),
        );

        $this->authorise($conversation->id)->assertUnauthorized();
    }

    public function test_a_thread_that_does_not_exist_authorises_nobody(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->authorise(9999)->assertForbidden();
    }
}
