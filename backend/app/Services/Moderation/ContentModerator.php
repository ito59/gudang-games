<?php

namespace App\Services\Moderation;

use App\Models\ModerationEvent;
use App\Models\User;
use Illuminate\Validation\ValidationException;

/**
 * The one door everything written by a member goes through.
 *
 * It runs on the server, not in the app, for the obvious reason: the app is
 * a program on somebody else's phone, and a filter that can be deleted is not
 * a filter. The app may run the same rules to fail faster, never instead.
 *
 * A rejection is reported to its author in the plainest terms that do not
 * double as instructions — "that word is not allowed here", never which word.
 */
class ContentModerator
{
    public function __construct(
        private readonly ProfanityFilter $profanity,
        private readonly SpamDetector $spam,
    ) {}

    /**
     * @param  string  $context  chat | post | comment
     */
    public function check(string $text, User $author, string $context): Verdict
    {
        if (! config('moderation.enabled', true)) {
            return Verdict::ok();
        }

        $match = $this->profanity->firstMatch($text);

        if ($match !== null) {
            return Verdict::reject(
                Verdict::profanity,
                'That message contains a word that is not allowed here.',
                $match,
            );
        }

        return $this->spam->check($text, $author, $context);
    }

    /**
     * Checks, logs a rejection, and stops the request.
     *
     * The exception is a [ValidationException] so it answers 422 with the
     * message under `body` — the same shape the app already handles for a
     * message that was too long, rather than a second failure mode it would
     * have to learn.
     */
    public function guard(string $text, User $author, string $context): void
    {
        $verdict = $this->check($text, $author, $context);

        if ($verdict->allowed) {
            return;
        }

        ModerationEvent::record($verdict, $author, $context, $text);

        throw ValidationException::withMessages([
            'body' => [$verdict->message],
        ]);
    }
}
