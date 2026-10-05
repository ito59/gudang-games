<?php

namespace Tests\Feature\Api;

use App\Models\Comment;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Post;
use App\Models\Report;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReportTest extends TestCase
{
    use RefreshDatabase;

    private function message(User $from, User $to, string $body = 'something rude'): Message
    {
        $conversation = Conversation::between($from, $to);

        return $conversation->messages()->create(['user_id' => $from->id, 'body' => $body]);
    }

    private function report(array $payload)
    {
        return $this->postJson('/api/v1/reports', $payload);
    }

    public function test_the_reason_list_is_public_so_both_ends_agree(): void
    {
        $this->getJson('/api/v1/report-reasons')
            ->assertOk()
            ->assertJsonPath('data.0.value', 'spam')
            ->assertJsonStructure(['data' => [['value', 'label']]]);
    }

    public function test_a_message_in_your_own_thread_can_be_reported(): void
    {
        [$viewer, $other] = [User::factory()->create(), User::factory()->create()];
        $message = $this->message($other, $viewer, 'you are terrible');

        Sanctum::actingAs($viewer);

        $this->report([
            'type' => 'message',
            'id' => $message->id,
            'reason' => 'harassment',
            'note' => 'been going on all week',
        ])->assertCreated();

        $report = Report::sole();

        $this->assertSame($viewer->id, $report->reporter_id);
        $this->assertSame($other->id, $report->reported_user_id);
        $this->assertSame(Message::class, $report->reportable_type);
        $this->assertSame('harassment', $report->reason);
        // The snapshot is what makes the queue readable after a delete.
        $this->assertSame('you are terrible', $report->excerpt);
        $this->assertTrue($report->isPending());
    }

    /**
     * Reporting is not a way to read somebody else's messages: a guessed id
     * must not come back with the text in the excerpt.
     */
    public function test_a_message_from_a_thread_you_are_not_in_is_closed_to_you(): void
    {
        [$a, $b, $outsider] = User::factory()->count(3)->create();
        $message = $this->message($a, $b, 'private business');

        Sanctum::actingAs($outsider);

        $this->report(['type' => 'message', 'id' => $message->id, 'reason' => 'spam'])
            ->assertForbidden();

        $this->assertDatabaseCount('reports', 0);
    }

    public function test_posts_comments_and_members_can_be_reported(): void
    {
        $author = User::factory()->create();
        $viewer = User::factory()->create();
        $post = Post::factory()->for($author, 'author')->create();
        $comment = Comment::create([
            'post_id' => $post->id,
            'user_id' => $author->id,
            'body' => 'rude reply',
        ]);

        Sanctum::actingAs($viewer);

        $this->report(['type' => 'post', 'id' => $post->id, 'reason' => 'spam'])->assertCreated();
        $this->report(['type' => 'comment', 'id' => $comment->id, 'reason' => 'hate'])->assertCreated();
        $this->report(['type' => 'user', 'id' => $author->id, 'reason' => 'harassment'])->assertCreated();

        $this->assertEqualsCanonicalizing(
            [Post::class, Comment::class, User::class],
            Report::pluck('reportable_type')->all(),
        );
        // All three point at the same member, which is what the queue counts.
        $this->assertSame([$author->id, $author->id, $author->id], Report::pluck('reported_user_id')->all());
    }

    /**
     * Answered as success rather than as an error: the reporter did what they
     * meant to, and an error invites them to file it again.
     */
    public function test_reporting_the_same_thing_twice_files_one_report(): void
    {
        $author = User::factory()->create();
        $post = Post::factory()->for($author, 'author')->create();

        Sanctum::actingAs(User::factory()->create());

        $this->report(['type' => 'post', 'id' => $post->id, 'reason' => 'spam'])->assertCreated();
        $this->report(['type' => 'post', 'id' => $post->id, 'reason' => 'hate'])
            ->assertOk()
            ->assertJsonPath('data.status', 'already_reported');

        $this->assertSame(1, Report::count());
    }

    /** Two people reporting the same thing is the signal the queue needs. */
    public function test_two_members_can_report_the_same_thing(): void
    {
        $post = Post::factory()->create();

        foreach (User::factory()->count(2)->create() as $reporter) {
            Sanctum::actingAs($reporter);
            $this->report(['type' => 'post', 'id' => $post->id, 'reason' => 'spam'])->assertCreated();
        }

        $this->assertSame(2, Report::count());
    }

    public function test_you_cannot_report_yourself(): void
    {
        $viewer = User::factory()->create();
        $post = Post::factory()->for($viewer, 'author')->create();

        Sanctum::actingAs($viewer);

        $this->report(['type' => 'user', 'id' => $viewer->id, 'reason' => 'spam'])
            ->assertStatus(422);
        $this->report(['type' => 'post', 'id' => $post->id, 'reason' => 'spam'])
            ->assertStatus(422);

        $this->assertDatabaseCount('reports', 0);
    }

    public function test_an_unknown_reason_or_target_is_refused(): void
    {
        $post = Post::factory()->create();
        Sanctum::actingAs(User::factory()->create());

        $this->report(['type' => 'post', 'id' => $post->id, 'reason' => 'because'])
            ->assertJsonValidationErrors('reason');
        $this->report(['type' => 'trailer', 'id' => 1, 'reason' => 'spam'])
            ->assertJsonValidationErrors('type');
        $this->report(['type' => 'post', 'id' => 9999, 'reason' => 'spam'])
            ->assertNotFound();
    }

    /** An unpublished post is not visible, so it is not reportable either. */
    public function test_a_hidden_post_cannot_be_reported(): void
    {
        $post = Post::factory()->hidden()->create();
        Sanctum::actingAs(User::factory()->create());

        $this->report(['type' => 'post', 'id' => $post->id, 'reason' => 'spam'])
            ->assertNotFound();
    }

    public function test_reporting_needs_a_token(): void
    {
        $post = Post::factory()->create();

        $this->report(['type' => 'post', 'id' => $post->id, 'reason' => 'spam'])
            ->assertUnauthorized();
    }
}
