<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ModerationEvent;
use App\Models\Report;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

/**
 * The review queue: what members reported, and what the filter refused.
 *
 * The two sit on one page because they answer each other. A member with
 * three reports and forty filter hits is a different problem from one with
 * three reports and none, and a queue that showed only half of that would
 * have an admin guessing.
 */
class ReportController extends Controller
{
    public function index(Request $request): Response
    {
        $status = $request->string('status')->value() ?: Report::pending;

        $reports = Report::query()
            ->when($status !== 'all', fn ($q) => $q->where('status', $status))
            ->with([
                'reporter:id,name,username',
                'reportedUser:id,name,username,is_active',
                'resolver:id,name',
                // Null once the content is gone, which is why the report
                // carries its own excerpt.
                'reportable',
            ])
            ->latest()
            ->paginate(15)
            ->withQueryString()
            ->through(fn (Report $report) => [
                'id' => $report->id,
                'target' => $report->target_name,
                'reason' => Report::reasons[$report->reason] ?? $report->reason,
                'note' => $report->note,
                'excerpt' => $report->excerpt,
                'status' => $report->status,
                'resolution' => $report->resolution,
                'content_exists' => $report->reportable !== null,
                'created_at' => $report->created_at?->diffForHumans(),
                'reporter' => $report->reporter?->only('id', 'name', 'username'),
                'reported_user' => $report->reportedUser
                    ? [
                        ...$report->reportedUser->only('id', 'name', 'username', 'is_active'),
                        // How much else is outstanding about this member,
                        // which is the number that decides an action.
                        'pending_reports' => Report::pending()
                            ->where('reported_user_id', $report->reportedUser->id)
                            ->count(),
                    ]
                    : null,
                'resolved_by' => $report->resolver?->name,
            ]);

        $flagged = ModerationEvent::query()
            ->with('author:id,name,username')
            ->latest()
            ->paginate(10, ['*'], 'flagged')
            ->withQueryString()
            ->through(fn (ModerationEvent $event) => [
                'id' => $event->id,
                'context' => $event->context,
                'reason' => $event->reason,
                'rule' => $event->rule,
                'body' => $event->body,
                'created_at' => $event->created_at?->diffForHumans(),
                'author' => $event->author?->only('id', 'name', 'username'),
            ]);

        return Inertia::render('Admin/Reports/Index', [
            'reports' => $reports,
            'flagged' => $flagged,
            'filters' => ['status' => $status],
            'counts' => [
                'pending' => Report::pending()->count(),
                'flagged' => ModerationEvent::count(),
            ],
        ]);
    }

    /**
     * Acts on a report and closes it.
     *
     * `dismiss` is a first-class outcome, not a way of giving up: most of
     * what lands in a queue like this is a disagreement rather than a breach,
     * and recording that keeps the next admin from re-reading it.
     */
    public function update(Request $request, Report $report): RedirectResponse
    {
        $data = $request->validate([
            'resolution' => ['required', Rule::in(['dismiss', 'delete_content', 'suspend_user'])],
        ]);

        $message = match ($data['resolution']) {
            'dismiss' => 'Report dismissed.',
            'delete_content' => $this->deleteContent($report),
            'suspend_user' => $this->suspend($report),
        };

        $report->update([
            'status' => $data['resolution'] === 'dismiss' ? Report::dismissed : Report::resolved,
            'resolution' => $data['resolution'],
            'resolved_by' => $request->user()->id,
            'resolved_at' => now(),
        ]);

        return back()->with('success', $message);
    }

    private function deleteContent(Report $report): string
    {
        $content = $report->reportable;

        if ($content === null) {
            return 'That content was already gone; the report is closed.';
        }

        // A member is not content. Suspending one is the other action, and
        // deleting an account from here would be a surprising thing for a
        // button labelled "delete content" to do.
        if ($content instanceof User) {
            return 'Reported members are suspended, not deleted; the report is closed.';
        }

        $content->delete();

        // Everything else anybody said about the same thing is now moot.
        Report::pending()
            ->where('reportable_type', $report->reportable_type)
            ->where('reportable_id', $report->reportable_id)
            ->whereKeyNot($report->id)
            ->update([
                'status' => Report::resolved,
                'resolution' => 'delete_content',
                'resolved_at' => now(),
            ]);

        return 'Content deleted.';
    }

    private function suspend(Report $report): string
    {
        $user = $report->reportedUser;

        if ($user === null) {
            return 'That member is gone; the report is closed.';
        }

        if ($user->is_admin) {
            return 'Administrators are suspended from the Users page, not from here.';
        }

        $user->update(['is_active' => false]);

        return "{$user->name} suspended.";
    }
}
