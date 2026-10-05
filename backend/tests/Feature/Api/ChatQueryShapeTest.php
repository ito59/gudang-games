<?php

namespace Tests\Feature\Api;

use App\Models\Conversation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * The shape of the queries the thread list runs, not just their answers.
 *
 * The suite runs on SQLite, which executes anything. Production runs on a
 * MySQL old enough to reject two of the things Eloquent will happily emit —
 * so a test that only checks the payload passes while the deployed app
 * throws. These assert the SQL itself.
 */
class ChatQueryShapeTest extends TestCase
{
    use RefreshDatabase;

    /** @return array<int, string> */
    private function queriesFor(callable $work): array
    {
        $seen = [];
        DB::listen(function ($query) use (&$seen) {
            $seen[] = strtolower($query->sql);
        });

        $work();

        return $seen;
    }

    private function assertPortable(array $queries): void
    {
        $this->assertNotEmpty($queries);

        foreach ($queries as $sql) {
            // `with(['messages' => fn ($q) => $q->limit(1)])` falls back to
            // these on a MySQL without window functions, and the server
            // answers 1463: non-grouping field used in HAVING clause.
            $this->assertStringNotContainsString('@laravel_row', $sql);
            $this->assertStringNotContainsString('having', $sql);
            // Window functions arrived in MySQL 8.
            $this->assertStringNotContainsString('over (', $sql);
        }
    }

    public function test_listing_threads_uses_no_query_the_old_server_refuses(): void
    {
        [$me, $them] = [User::factory()->create(), User::factory()->create()];
        $conversation = Conversation::between($me, $them);
        $conversation->messages()->create(['user_id' => $them->id, 'body' => 'One']);
        $conversation->messages()->create(['user_id' => $them->id, 'body' => 'Two']);

        Sanctum::actingAs($me);

        $queries = $this->queriesFor(function () {
            $this->getJson('/api/v1/conversations')
                ->assertOk()
                // Still the right answer, not just portable SQL.
                ->assertJsonPath('data.0.last_message.body', 'Two');
        });

        $this->assertPortable($queries);
    }

    public function test_opening_a_thread_does_the_same(): void
    {
        [$me, $them] = [User::factory()->create(), User::factory()->create()];

        Sanctum::actingAs($me);

        $queries = $this->queriesFor(function () use ($them) {
            $this->postJson('/api/v1/conversations', ['user_id' => $them->id])
                ->assertSuccessful();
        });

        $this->assertPortable($queries);
    }
}
