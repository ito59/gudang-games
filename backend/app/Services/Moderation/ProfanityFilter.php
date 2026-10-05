<?php

namespace App\Services\Moderation;

/**
 * Whole-word matching against the list in `config/moderation.php`, over every
 * reading [TextNormaliser] produces.
 *
 * Whole words rather than substrings, because substring matching is how a
 * filter ends up rejecting "class", "Scunthorpe" and "bangsa". The cost is
 * that a word glued to another is missed; the normaliser's narrow folds take
 * back most of that without the false positives.
 */
class ProfanityFilter
{
    /** @var array<string, true> */
    private array $words;

    /** @var array<string, true> */
    private array $allowed;

    public function __construct(private readonly TextNormaliser $normaliser)
    {
        $this->words = $this->set(config('moderation.profanity.words', []));
        $this->allowed = $this->set(config('moderation.profanity.allow', []));
    }

    /** The first blocked word found, or null when the text is clean. */
    public function firstMatch(string $text): ?string
    {
        foreach ($this->normaliser->variants($text) as $variant) {
            foreach (explode(' ', $variant) as $token) {
                if ($token === '' || isset($this->allowed[$token])) {
                    continue;
                }

                if (isset($this->words[$token])) {
                    return $token;
                }
            }
        }

        return null;
    }

    public function isClean(string $text): bool
    {
        return $this->firstMatch($text) === null;
    }

    /**
     * @param  iterable<string>  $words
     * @return array<string, true>
     */
    private function set(iterable $words): array
    {
        $set = [];

        foreach ($words as $word) {
            $word = strtolower(trim((string) $word));

            if ($word !== '') {
                $set[$word] = true;
            }
        }

        return $set;
    }
}
