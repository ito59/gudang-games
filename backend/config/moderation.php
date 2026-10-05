<?php

return [
    /*
     * Turning this off lets everything through. It exists for local work and
     * for the seeder, not as a setting anyone should reach for in production:
     * the filter runs server-side because the app cannot be trusted to run it
     * at all, and a disabled server filter is the same as having none.
     */
    'enabled' => env('MODERATION_ENABLED', true),

    'profanity' => [
        /*
         * Matched as whole words, after the text is normalised — case,
         * accents, leetspeak, stretched letters and punctuation inside a word
         * are all folded away first, so one entry covers `A-N-J-1-N-G` too.
         * See [App\Services\Moderation\TextNormaliser].
         *
         * Only unambiguous abuse belongs here. Mild slang (`anjir`, `anjay`,
         * `kampret`) is deliberately absent: blocking it annoys people who
         * were not being abusive and teaches them to work around the filter,
         * which costs more than it saves.
         *
         * The consonant-only spellings (`kntl`, `fck`) are here because
         * dropping vowels is the most common way past a word list, and
         * catching it generally would flag too much ordinary text.
         */
        'words' => [
            // Indonesian
            'anjing', 'anjeng', 'anjg', 'asu', 'bajingan', 'bangsat', 'bangke',
            'bencong', 'brengsek', 'cukimai', 'cukimay', 'entot', 'goblok',
            'jancok', 'jancuk', 'jembut', 'kampang', 'keparat', 'kimak',
            'kntl', 'kontol', 'lonte', 'memek', 'mmk', 'ngentot', 'ngentod',
            'ngewe', 'pantek', 'pelacur', 'pepek', 'perek', 'pukimak', 'puki',
            'sundal', 'tolol', 'babi',

            // English
            'arsehole', 'asshole', 'bastard', 'bitch', 'bollocks', 'bullshit',
            'cunt', 'dickhead', 'fag', 'faggot', 'fck', 'fuck', 'fucker',
            'fucking', 'motherfucker', 'nigga', 'nigger', 'prick', 'pussy',
            'retard', 'retarded', 'shit', 'slut', 'twat', 'whore', 'wanker',
        ],

        /*
         * Words the normaliser would otherwise fold onto a blocked one.
         * `masa` survives collapsing `massa`, and `bab` is a chapter.
         */
        'allow' => ['masa', 'bab', 'asuh', 'asus', 'basi'],
    ],

    'spam' => [
        /*
         * Two windows, because they catch different things: the burst stops a
         * script pasting the same line forty times, the minute stops somebody
         * settling into a slower flood that no single burst would notice.
         */
        'burst' => ['limit' => 5, 'seconds' => 10],
        'per_minute' => 20,

        /* The same thing said twice inside this window is a repeat. */
        'repeat_minutes' => 10,

        /* Links per message. Two lets somebody share a clip and its source. */
        'max_links' => 2,

        /* SHOUTING, but only once a message is long enough to mean it. */
        'shout_ratio' => 0.7,
        'shout_min_length' => 20,

        /* `aaaaaaaaaaaaaa`. Long enough that emphasis still gets through. */
        'max_repeated_chars' => 12,
    ],
];
