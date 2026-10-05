<?php

namespace App\Services\Push;

/** What a person sees on their lock screen, and what the app does with a tap. */
class PushMessage
{
    /**
     * @param  array<string, string>  $data  Read by the app, not shown.
     */
    public function __construct(
        public readonly string $title,
        public readonly string $body,
        public readonly array $data = [],
    ) {}
}
