<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;

/**
 * What the app needs to know about this deployment before anyone signs in.
 *
 * Serving the Google client ID here means it is configured once, on the
 * server, instead of being compiled into every build and having to agree with
 * what the server accepts. OAuth client IDs are public identifiers — they ship
 * inside every app that uses them — so there is nothing secret to leak.
 */
class ConfigController extends Controller
{
    public function show(): JsonResponse
    {
        return response()->json([
            'google' => [
                'enabled' => config('services.google.client_ids') !== [],
                // An unset env var reads as '' rather than null; the app
                // treats both as absent, but null is the honest answer.
                'server_client_id' => config('services.google.server_client_id') ?: null,
                'ios_client_id' => config('services.google.ios_client_id') ?: null,
            ],
            // Same reasoning as the Google block: the Reverb app key is a
            // public identifier every client needs, and where the socket
            // lives is a deployment detail, not something to compile in.
            'realtime' => $this->realtime(),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function realtime(): array
    {
        $connection = config('broadcasting.connections.reverb');
        $key = $connection['key'] ?? null;
        $host = $connection['options']['host'] ?? null;

        if (blank($key) || blank($host) || config('broadcasting.default') !== 'reverb') {
            return ['enabled' => false];
        }

        $scheme = $connection['options']['scheme'] ?? 'https';

        return [
            'enabled' => true,
            'key' => $key,
            'host' => $host,
            'port' => (int) ($connection['options']['port'] ?? 443),
            'scheme' => $scheme === 'https' ? 'wss' : 'ws',
        ];
    }
}
