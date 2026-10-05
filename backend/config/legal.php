<?php

/*
 * Who stands behind the app, as the privacy policy and terms name them. Play
 * Console links to both pages, and reviewers check that the operator and a way
 * to reach them are on the page itself, so neither may be left blank in
 * production.
 */
return [
    'app_name' => env('LEGAL_APP_NAME', 'BandarGames'),

    'operator' => env('LEGAL_OPERATOR', 'PT LDS'),

    'website' => env('LEGAL_WEBSITE', 'https://lds.co.id'),

    'contact_email' => env('LEGAL_CONTACT_EMAIL'),

    'package' => 'id.co.lds.bandargames',

    /*
     * The landing page's download button. Left empty while the listing is
     * still in closed testing, where a public link would only 404; the page
     * then says the app is coming soon instead.
     */
    'play_store_url' => env('PLAY_STORE_URL'),

    'minimum_age' => 13,

    /*
     * Bump this whenever the text changes in substance; the pages print it as
     * the date the current version took effect.
     */
    'effective_date' => '2026-09-23',
];
