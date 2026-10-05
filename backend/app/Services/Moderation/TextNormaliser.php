<?php

namespace App\Services\Moderation;

use Illuminate\Support\Str;

/**
 * Folds the ways people write around a word list back onto plain letters.
 *
 * A word list only ever matches what it is shown, so the work is here rather
 * than in the list: `A N J 1 N G`, `anjjjjing` and `a.n.j.i.n.g` all have to
 * arrive at `anjing` before anything is compared.
 *
 * It produces several variants instead of one canonical string on purpose.
 * Each fold that catches an evasion also risks inventing a word that was
 * never written — squashing spaces turns "bangsa tercinta" into something
 * containing "bangsat" — so the aggressive folds are applied narrowly, and
 * the caller matches whole words against every variant separately.
 */
class TextNormaliser
{
    /**
     * Digits standing in for letters. Safe to replace wherever they appear:
     * a digit is hardly ever punctuation, so `pl4yer` and `5h17` both fold
     * and the cost is that `top 10` reads as `top io`, which matches nothing.
     */
    private const LEET_DIGITS = [
        '0' => 'o', '1' => 'i', '2' => 'z', '3' => 'e', '4' => 'a',
        '5' => 's', '6' => 'g', '7' => 't', '8' => 'b', '9' => 'g',
    ];

    /**
     * Symbols standing in for letters, replaced only when a letter or digit
     * follows — `sh!t` and `@ss`, but not the `!` in `nice shot!`, which is
     * punctuation and would otherwise fold into a word nobody wrote.
     *
     * `*` is absent: it replaces a letter rather than standing for one, and
     * the consonant-only spellings in the word list cover what it leaves.
     */
    private const LEET_SYMBOLS = [
        '@' => 'a', '(' => 'c', '!' => 'i', '|' => 'i', '$' => 's', '+' => 't',
    ];

    /**
     * Every reading of [$text] worth matching a word list against.
     *
     * @return list<string> lowercase, each a space-separated list of tokens
     */
    public function variants(string $text): array
    {
        $base = $this->fold($text);

        $variants = [
            // As written, give or take case, accents and leetspeak.
            $this->tokenise($base),
            // `anjjjjing`, and `anjiing` which the first fold leaves alone.
            $this->tokenise($this->collapseRuns($base, 3)),
            $this->tokenise($this->collapseRuns($base, 2)),
            // `a.n.j.i.n.g` and `anj_ing`. Spaces are kept, so no two
            // innocent words are joined into a guilty one.
            $this->tokenise($this->stripPunctuationInsideWords($base)),
            // `a n j i n g`, where the separator is the space itself. Only
            // runs of single letters are joined, which ordinary prose has
            // none of.
            $this->joinSpeltOutRuns($this->tokenise($base)),
        ];

        return array_values(array_unique(array_filter($variants)));
    }

    /** Lowercase, accent-free, leetspeak resolved. */
    private function fold(string $text): string
    {
        $text = strtr(Str::lower(Str::ascii($text)), self::LEET_DIGITS);

        $symbols = preg_quote(implode('', array_keys(self::LEET_SYMBOLS)), '/');

        return (string) preg_replace_callback(
            '/(['.$symbols.'])(?=[a-z0-9])/',
            fn (array $m) => self::LEET_SYMBOLS[$m[1]],
            $text,
        );
    }

    /**
     * One string per piece of text, for recognising the same thing said
     * twice: letters and digits only, and no leetspeak, so that `!!!` on the
     * end changes nothing while `h3llo` and `hello` stay distinct enough not
     * to be worth folding together.
     */
    public function fingerprint(string $text): string
    {
        return (string) preg_replace('/[^a-z0-9]+/', '', Str::lower(Str::ascii($text)));
    }

    /** Letters and digits only, everything else a single space. */
    private function tokenise(string $text): string
    {
        return trim((string) preg_replace('/[^a-z0-9]+/', ' ', $text));
    }

    /** `aaaa` → `a`, for runs of [$min] or more. */
    private function collapseRuns(string $text, int $min): string
    {
        $quantifier = $min - 1;

        return (string) preg_replace('/(.)\1{'.$quantifier.',}/u', '$1', $text);
    }

    /** `a.n.j.i.n.g` → `anjing`, leaving spaces between words alone. */
    private function stripPunctuationInsideWords(string $text): string
    {
        return (string) preg_replace('/(?<=[a-z0-9])[^a-z0-9 ]+(?=[a-z0-9])/', '', $text);
    }

    /**
     * Joins runs of three or more single-letter tokens: `a n j i n g` reads
     * as one word, while `i am a fan` keeps its two-letter tokens and is left
     * as it was.
     */
    private function joinSpeltOutRuns(string $tokens): string
    {
        if ($tokens === '') {
            return '';
        }

        $out = [];
        $run = [];

        $flush = function () use (&$out, &$run) {
            if (count($run) >= 3) {
                $out[] = implode('', $run);
            } else {
                array_push($out, ...$run);
            }
            $run = [];
        };

        foreach (explode(' ', $tokens) as $token) {
            if (strlen($token) === 1) {
                $run[] = $token;

                continue;
            }

            $flush();
            $out[] = $token;
        }

        $flush();

        return implode(' ', $out);
    }
}
