<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'google' => [

        /*
         * The web OAuth client. Android asks Google for a token aimed at this
         * one, so it is what lands in the token's `aud` — and it is handed to
         * the app over /api/v1/config, so the client ID lives in one place
         * instead of having to match a value compiled into the build.
         *
         * A client ID is public by design; there is no secret here.
         */
        'server_client_id' => env('GOOGLE_SERVER_CLIENT_ID'),

        /* Only for an iOS build, which stamps its own client ID instead. */
        'ios_client_id' => env('GOOGLE_IOS_CLIENT_ID'),

        /*
         * Audiences this server accepts. Defaults to the two clients above,
         * which is what a normal deployment wants; set GOOGLE_CLIENT_IDS
         * (comma separated) only to accept something else as well. Empty
         * turns Google sign-in off rather than accepting anything.
         */
        'client_ids' => \App\Services\Google\ClientIds::accepted(
            env('GOOGLE_CLIENT_IDS'),
            env('GOOGLE_SERVER_CLIENT_ID'),
            env('GOOGLE_IOS_CLIENT_ID'),
        ),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

];
