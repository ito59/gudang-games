<?php

namespace Tests\Feature\Admin;

use App\Models\ModerationEvent;
use App\Models\Post;
use App\Models\Report;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReportQueueTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->create(['is_admin' => true]);
    }

    private function reportOn(Post $post, ?User $reporter = null): Report
    {
        $reporter ??= User::factory()->create();

        return Report::create([
            'reporter_id' => $reporter->id,
            'reportable_type' => Post::class,
            'reportable_id' => $post->id,
            'reason' => 'spam',
            'excerpt' => $post->body,
            'reported_user_id' => $post->user_id,
        ]);
    }

    public function test_the_queue_is_for_admins_only(): void
    {
        $this->get('/admin/reports')->assertRedirect('/login');

        $this->actingAs(User::factory()->create())
            ->get('/admin/reports')
            ->assertForbidden();

        $this->actingAs($this->admin())->get('/admin/reports')->assertOk();
    }

    public function test_it_lists_what_is_pending_and_what_the_filter_refused(): void
    {
        $post = Post::factory()->create();
        $this->reportOn($post);
        ModerationEvent::create([
            'user_id' => User::factory()->create()->id,
            'context' => 'chat',
            'reason' => 'profanity',
            'rule' => 'kontol',
            'body' => 'dasar kontol',
        ]);

        $this->actingAs($this->admin())
            ->get('/admin/reports')
            ->assertOk()
            ->assertInertia(fn ($page) => $page
                ->component('Admin/Reports/Index')
                ->has('reports.data', 1)
                ->where('reports.data.0.target', 'post')
                ->where('reports.data.0.reason', 'Spam or scam')
                ->where('reports.data.0.content_exists', true)
                ->has('flagged.data', 1)
                ->where('flagged.data.0.rule', 'kontol')
                ->where('counts.pending', 1));
    }

    public function test_dismissing_closes_the_report_and_leaves_the_content(): void
    {
        $post = Post::factory()->create();
        $report = $this->reportOn($post);

        $this->actingAs($this->admin())
            ->patch("/admin/reports/{$report->id}", ['resolution' => 'dismiss'])
            ->assertRedirect();

        $this->assertSame(Report::dismissed, $report->fresh()->status);
        $this->assertNotNull($report->fresh()->resolved_at);
        $this->assertModelExists($post);
    }

    /** One decision about one piece of content settles every report of it. */
    public function test_deleting_content_closes_the_other_reports_of_it(): void
    {
        $post = Post::factory()->create();
        $mine = $this->reportOn($post);
        $theirs = $this->reportOn($post);
        $unrelated = $this->reportOn(Post::factory()->create());

        $admin = $this->admin();

        $this->actingAs($admin)
            ->patch("/admin/reports/{$mine->id}", ['resolution' => 'delete_content']);

        $this->assertModelMissing($post);
        $this->assertSame(Report::resolved, $mine->fresh()->status);
        $this->assertSame($admin->id, $mine->fresh()->resolved_by);
        $this->assertSame(Report::resolved, $theirs->fresh()->status);
        $this->assertSame(Report::pending, $unrelated->fresh()->status);
    }

    public function test_a_report_about_deleted_content_can_still_be_closed(): void
    {
        $post = Post::factory()->create();
        $report = $this->reportOn($post);
        $post->delete();

        $this->actingAs($this->admin())
            ->patch("/admin/reports/{$report->id}", ['resolution' => 'delete_content'])
            ->assertRedirect();

        $this->assertSame(Report::resolved, $report->fresh()->status);
    }

    public function test_suspending_takes_the_members_access_away(): void
    {
        $author = User::factory()->create(['is_active' => true]);
        $report = $this->reportOn(Post::factory()->for($author, 'author')->create());

        $this->actingAs($this->admin())
            ->patch("/admin/reports/{$report->id}", ['resolution' => 'suspend_user']);

        $this->assertFalse($author->fresh()->is_active);
        $this->assertSame(Report::resolved, $report->fresh()->status);
    }

    /** The Users page is where an admin's own access is changed, with its
     *  last-administrator guard. This route must not be a way around it. */
    public function test_an_administrator_is_not_suspended_from_here(): void
    {
        $other = User::factory()->create(['is_admin' => true]);
        $report = $this->reportOn(Post::factory()->for($other, 'author')->create());

        $this->actingAs($this->admin())
            ->patch("/admin/reports/{$report->id}", ['resolution' => 'suspend_user']);

        $this->assertTrue($other->fresh()->is_active);
    }

    /** Members are suspended, not deleted, whatever the button said. */
    public function test_deleting_content_never_deletes_a_member(): void
    {
        $member = User::factory()->create();
        $report = Report::create([
            'reporter_id' => User::factory()->create()->id,
            'reportable_type' => User::class,
            'reportable_id' => $member->id,
            'reason' => 'harassment',
            'reported_user_id' => $member->id,
        ]);

        $this->actingAs($this->admin())
            ->patch("/admin/reports/{$report->id}", ['resolution' => 'delete_content']);

        $this->assertModelExists($member);
    }

    public function test_an_unknown_resolution_is_refused(): void
    {
        $report = $this->reportOn(Post::factory()->create());

        $this->actingAs($this->admin())
            ->patch("/admin/reports/{$report->id}", ['resolution' => 'ban_forever'])
            ->assertSessionHasErrors('resolution');

        $this->assertTrue($report->fresh()->isPending());
    }
}
