<?php

namespace App\Http\Controllers\Api;

use App\Events\MessageSent;
use App\Events\ThreadRead;
use App\Http\Controllers\Controller;
use App\Http\Resources\ConversationResource;
use App\Http\Resources\MessageResource;
use App\Models\Conversation;
use App\Models\User;
use App\Services\Moderation\ContentModerator;
use App\Services\Push\Notifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Throwable;

/**
 * One-to-one threads between members.
 *
 * Every route here is a participant's own: reading or writing a thread you
 * are not in is a 403, not an empty list, so a guessed id says nothing.
 *
 * A block hides the thread from both of them and refuses both of them the
 * write. Hiding it from the blocked member as well leaks that something
 * happened — but so does a message that never arrives, and this way neither
 * of them is left talking into a room the other cannot read. Unblocking
 * brings the thread back; nothing was deleted.
 */
class ChatController extends Controller
{
    /** The viewer's threads, most recently spoken in first. */
    public function index(Request $request): AnonymousResourceCollection
    {
        $viewer = $request->user();
        $hidden = $viewer->hiddenUserIds();

        $conversations = Conversation::forMember($viewer)
            ->when($hidden !== [], fn ($q) => $q->whereDoesntHave(
                'participants',
                fn ($p) => $p->whereIn('users.id', $hidden),
            ))
            ->with([
                'participants:id,name,username,accent_color,avatar_path,playing,last_seen_at',
                // Only the latest, which is all the list shows.
                'latestMessage',
            ])
            // Theirs, and newer than the last one this member has seen.
            ->withCount(['messages as unread_count' => fn ($q) => $q
                ->where('messages.user_id', '!=', $viewer->id)
                ->whereRaw('messages.id > coalesce(conversation_user.last_read_message_id, 0)')])
            ->get();

        return ConversationResource::collection($conversations);
    }

    /**
     * Opens the thread with another member, making it if this is their first
     * message. Tapping Message twice lands in the same place.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'user_id' => ['required', 'integer', 'exists:users,id'],
        ]);

        $viewer = $request->user();
        $other = User::findOrFail($data['user_id']);

        abort_if($viewer->is($other), 422, 'You cannot message yourself.');
        abort_if($viewer->isSeparatedFrom($other), 403, 'You cannot message this member.');

        $conversation = Conversation::between($viewer, $other);

        return $this->one($request, $conversation)
            ->response()
            ->setStatusCode($conversation->wasRecentlyCreated ? 201 : 200);
    }

    /** A thread's messages, oldest first so it reads top to bottom. */
    public function messages(Request $request, Conversation $conversation): AnonymousResourceCollection
    {
        $this->assertParticipant($request, $conversation);
        $this->assertNotBlocked($request, $conversation);

        $messages = $conversation->messages()
            ->with('author:id,name,username,accent_color,avatar_path')
            ->orderBy('id')
            ->paginate(50);

        return MessageResource::collection($messages);
    }

    public function send(Request $request, Conversation $conversation): JsonResponse
    {
        $this->assertParticipant($request, $conversation);
        $this->assertNotBlocked($request, $conversation);

        $data = $request->validate([
            'body' => ['required', 'string', 'max:2000'],
        ]);

        // Before the insert, so nothing that fails the filter is ever stored,
        // broadcast or pushed to the other phone.
        app(ContentModerator::class)->guard($data['body'], $request->user(), 'chat');

        $message = $conversation->messages()->create([
            'user_id' => $request->user()->id,
            'body' => $data['body'],
        ]);

        $conversation->update(['last_message_at' => $message->created_at]);

        $this->tell(new MessageSent($message));
        // The socket reaches an app that is open; this reaches a phone in a
        // pocket. Both, because either alone leaves somebody uninformed.
        app(Notifier::class)->messageSent($message);

        $message->load('author:id,name,username,accent_color,avatar_path');

        return (new MessageResource($message))->response()->setStatusCode(201);
    }

    /** Everything up to now has been seen. */
    public function read(Request $request, Conversation $conversation): JsonResponse
    {
        $this->assertParticipant($request, $conversation);

        $latest = $conversation->messages()->max('id');

        $conversation->participants()->updateExistingPivot(
            $request->user()->id,
            ['last_read_message_id' => $latest]
        );

        // The other seat is what this is for: their ticks turn blue while
        // they are looking, rather than the next time they reopen the thread.
        $this->tell(new ThreadRead($conversation, $request->user(), $latest));

        return response()->json(['last_read_message_id' => $latest]);
    }

    /**
     * Tells the other seat, and does not let a silent socket lose anything.
     *
     * Whatever prompted this is already saved by the time it runs. If Reverb
     * is down, letting the exception through would answer 500 — a sender
     * would be told their message did not send while it sat in the database,
     * and the other side would find it on their next load. Live delivery is
     * best effort; what it describes is not.
     */
    private function tell(object $event): void
    {
        try {
            // The person who caused it already has it on screen.
            broadcast($event)->toOthers();
        } catch (Throwable $e) {
            report($e);
        }
    }

    /**
     * 403 rather than 404: the thread does exist and they were in it. What
     * they are not told is which of them ended it.
     */
    private function assertNotBlocked(Request $request, Conversation $conversation): void
    {
        $conversation->loadMissing('participants:id');

        $viewer = $request->user();
        $other = $conversation->otherThan($viewer);

        abort_if($other !== null && $viewer->isSeparatedFrom($other), 403);
    }

    private function assertParticipant(Request $request, Conversation $conversation): void
    {
        $conversation->loadMissing('participants:id');

        abort_unless($conversation->includes($request->user()), 403);
    }

    private function one(Request $request, Conversation $conversation): ConversationResource
    {
        $conversation->load([
            'participants:id,name,username,accent_color,avatar_path,playing,last_seen_at',
            'latestMessage',
        ]);
        $conversation->unread_count = 0;

        return new ConversationResource($conversation);
    }
}
