<?php

namespace App\Services\Moderation;

use App\Models\User;
use Illuminate\Support\Facades\Cache;

/**
 * The shapes spam takes that a word list cannot see: the same line over and
 * over, a burst nobody types by hand, a wall of links, a wall of capitals.
 *
 * Counters live in the cache rather than a table. They answer a question
 * about the last few seconds and are worthless a minute later, so losing them
 * to a cache flush costs nothing — the worst case is that a flood gets a few
 * more messages through, and each one is still checked on its own merits.
 */
class SpamDetector
{
    public function __construct(private readonly TextNormaliser $normaliser) {}

    /**
     * [$context] separates the counters, so a busy conversation never uses up
     * somebody's allowance for posting.
     */
    public function check(string $text, User $author, string $context): Verdict
    {
        $config = config('moderation.spam');

        if ($this->exceedsLinks($text, (int) $config['max_links'])) {
            return Verdict::reject(
                Verdict::spam,
                'That looks like link spam. Try again with fewer links.',
                'links',
            );
        }

        if ($this->isShouting($text, (float) $config['shout_ratio'], (int) $config['shout_min_length'])) {
            return Verdict::reject(
                Verdict::spam,
                'That is almost all capitals. Try again without the shouting.',
                'shouting',
            );
        }

        if ($this->isKeyMashing($text, (int) $config['max_repeated_chars'])) {
            return Verdict::reject(
                Verdict::spam,
                'That has a very long run of one character.',
                'repeated-characters',
            );
        }

        if ($this->isRepeat($text, $author, $context, (int) $config['repeat_minutes'])) {
            return Verdict::reject(
                Verdict::spam,
                'You just said that. Say something else.',
                'repeat',
            );
        }

        $burst = $config['burst'];

        if ($this->tooMany("burst:$context", $author, (int) $burst['limit'], (int) $burst['seconds'])) {
            return Verdict::reject(
                Verdict::spam,
                'You are going too fast. Wait a moment and try again.',
                'burst',
            );
        }

        if ($this->tooMany("minute:$context", $author, (int) $config['per_minute'], 60)) {
            return Verdict::reject(
                Verdict::spam,
                'You have sent a lot in the last minute. Wait a moment and try again.',
                'flood',
            );
        }

        $this->remember($text, $author, $context, (int) $config['repeat_minutes']);

        return Verdict::ok();
    }

    private function exceedsLinks(string $text, int $max): bool
    {
        $found = preg_match_all(
            '~\b(?:https?://|www\.)\S+|\b[a-z0-9][a-z0-9-]*\.(?:com|net|org|io|gg|me|xyz|link|id|co)\b~i',
            $text,
        );

        return $found > $max;
    }

    private function isShouting(string $text, float $ratio, int $minLength): bool
    {
        $letters = preg_replace('/[^a-zA-Z]/', '', $text) ?? '';

        if (strlen($letters) < $minLength) {
            return false;
        }

        $upper = strlen(preg_replace('/[^A-Z]/', '', $letters) ?? '');

        return $upper / strlen($letters) >= $ratio;
    }

    private function isKeyMashing(string $text, int $max): bool
    {
        return (bool) preg_match('/(\S)\1{'.$max.',}/u', $text);
    }

    private function isRepeat(string $text, User $author, string $context, int $minutes): bool
    {
        return $minutes > 0 && Cache::has($this->repeatKey($text, $author, $context));
    }

    private function remember(string $text, User $author, string $context, int $minutes): void
    {
        if ($minutes > 0) {
            Cache::put($this->repeatKey($text, $author, $context), true, $minutes * 60);
        }
    }

    /**
     * Keyed by the text's fingerprint, so adding punctuation or capitals to
     * the same line does not make it a new one.
     */
    private function repeatKey(string $text, User $author, string $context): string
    {
        return sprintf(
            'moderation:said:%d:%s:%s',
            $author->id,
            $context,
            md5($this->normaliser->fingerprint($text)),
        );
    }

    /**
     * A fixed window: [Cache::add] sets the expiry once and the increments
     * leave it alone, so the allowance refills at a predictable moment rather
     * than being pushed further away by every attempt.
     */
    private function tooMany(string $bucket, User $author, int $limit, int $seconds): bool
    {
        $key = "moderation:rate:{$author->id}:{$bucket}";

        Cache::add($key, 0, $seconds);

        return Cache::increment($key) > $limit;
    }
}
