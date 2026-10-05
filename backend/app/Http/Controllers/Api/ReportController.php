<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Comment;
use App\Models\Message;
use App\Models\Post;
use App\Models\Report;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

/**
 * A member telling us about a message, post, comment or another member.
 *
 * Nothing here hides anything. A report is one person's account, filed for an
 * admin to judge; letting it remove content would hand every member a way to
 * silence anyone they disagreed with. Blocking is the control a reporter has
 * over their own experience, and it is a separate button.
 */
class ReportController extends Controller
{
    /** What the app shows in its reason list, so the two cannot drift. */
    public function reasons(): JsonResponse
    {
        return response()->json([
            'data' => collect(Report::reasons)
                ->map(fn (string $label, string $value) => compact('value', 'label'))
                ->values(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'type' => ['required', Rule::in(array_keys(Report::targets))],
            'id' => ['required', 'integer', 'min:1'],
            'reason' => ['required', Rule::in(array_keys(Report::reasons))],
            'note' => ['nullable', 'string', 'max:500'],
        ]);

        $reporter = $request->user();
        $target = $this->findVisible($reporter, $data['type'], (int) $data['id']);

        $author = $this->authorOf($target);

        abort_if($author !== null && $reporter->is($author), 422, 'You cannot report yourself.');

        try {
            $report = Report::create([
                'reporter_id' => $reporter->id,
                'reportable_type' => $target->getMorphClass(),
                'reportable_id' => $target->getKey(),
                'reason' => $data['reason'],
                'note' => $data['note'] ?? null,
                'excerpt' => $this->excerptOf($target),
                'reported_user_id' => $author?->id,
            ]);
        } catch (QueryException $e) {
            // The unique index caught a second report of the same thing.
            // Answered as success: the reporter did what they meant to, and
            // saying "already reported" invites them to try to file it again.
            if (! $this->isDuplicate($e)) {
                throw $e;
            }

            return response()->json(['data' => ['status' => 'already_reported']]);
        }

        return response()->json(
            ['data' => ['id' => $report->id, 'status' => $report->status]],
            201,
        );
    }

    /**
     * The reported thing, as this member can see it.
     *
     * A message is only reportable from inside its own thread, so an id
     * guessed from outside answers 403 rather than confirming the message
     * exists and handing over its text in the report excerpt.
     */
    private function findVisible(User $reporter, string $type, int $id): Model
    {
        return match ($type) {
            'message' => $this->visibleMessage($reporter, $id),
            'post' => Post::published()->findOrFail($id),
            'comment' => Comment::findOrFail($id),
            'user' => User::findOrFail($id),
        };
    }

    private function visibleMessage(User $reporter, int $id): Message
    {
        $message = Message::with('conversation.participants:id')->findOrFail($id);

        abort_unless($message->conversation?->includes($reporter) ?? false, 403);

        return $message;
    }

    private function authorOf(Model $target): ?User
    {
        return match (true) {
            $target instanceof User => $target,
            default => $target->author,
        };
    }

    /** Enough to recognise what was reported, not the whole of it. */
    private function excerptOf(Model $target): ?string
    {
        if ($target instanceof User) {
            return Str::limit((string) $target->bio, 280) ?: null;
        }

        return Str::limit((string) $target->body, 280);
    }

    private function isDuplicate(QueryException $e): bool
    {
        // 23000 covers the integrity-constraint family across drivers, which
        // here can only be the one unique index on this table.
        return ($e->errorInfo[0] ?? null) === '23000';
    }
}
