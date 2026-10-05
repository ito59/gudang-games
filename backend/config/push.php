<?php

return [
    /*
     * Firebase Cloud Messaging. Leave unset and the app still works — the
     * phones simply do not buzz, and each skipped notification is logged.
     *
     * `credentials` is the path to a service account JSON downloaded from
     * Firebase Console → Project settings → Service accounts. Keep it out of
     * the repository: it can send notifications to every install.
     */
    'fcm' => [
        'project_id' => env('FCM_PROJECT_ID', ''),
        'credentials' => env('FCM_CREDENTIALS', storage_path('app/firebase.json')),
    ],

    /*
     * The topic every install subscribes to while news notifications are on.
     * One send reaches all of them, however many there are.
     */
    'news_topic' => env('FCM_NEWS_TOPIC', 'news'),
];
