<?php

namespace App\Services\Push;

use App\Models\DeviceToken;
use App\Models\User;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Firebase Cloud Messaging, HTTP v1.
 *
 * Uses the `google/auth` package already here for Google sign-in, so a
 * service account JSON is the only new thing a deployment needs.
 *
 * Nothing here is allowed to break the thing that prompted it. A message is
 * sent and a news article is published whether or not a phone can be reached;
 * a failed notification is logged and the request carries on.
 */
class FcmPush implements Push
{
    public function __construct(
        private readonly string $projectId,
        private readonly string $credentialsPath,
    ) {}

    public function isConfigured(): bool
    {
        return $this->projectId !== '' && is_readable($this->credentialsPath);
    }

    public function toUser(User $user, PushMessage $message): void
    {
        $tokens = $user->deviceTokens()->pluck('token', 'id');

        foreach ($tokens as $id => $token) {
            $this->send(['token' => $token], $message, staleTokenId: $id);
        }
    }

    public function toTopic(string $topic, PushMessage $message): void
    {
        // One call however many devices are subscribed, which is why news
        // goes by topic rather than by walking every member's tokens.
        $this->send(['topic' => $topic], $message);
    }

    /**
     * @param  array<string, string>  $target
     */
    private function send(array $target, PushMessage $message, ?int $staleTokenId = null): void
    {
        try {
            $response = Http::withToken($this->accessToken())
                ->timeout(10)
                ->post(
                    "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send",
                    [
                        'message' => [
                            ...$target,
                            'notification' => [
                                'title' => $message->title,
                                'body' => $message->body,
                            ],
                            'data' => $message->data,
                            'android' => ['priority' => 'high'],
                        ],
                    ],
                );

            if ($response->successful()) {
                return;
            }

            // 404 UNREGISTERED means the app was uninstalled or the token was
            // replaced. Keeping it would mean retrying it forever.
            if ($staleTokenId !== null && in_array($response->status(), [400, 404], true)) {
                DeviceToken::whereKey($staleTokenId)->delete();
            }

            Log::warning('push refused', [
                'status' => $response->status(),
                'body' => $response->json() ?? $response->body(),
            ]);
        } catch (Throwable $e) {
            report($e);
        }
    }

    private function accessToken(): string
    {
        $credentials = new ServiceAccountCredentials(
            'https://www.googleapis.com/auth/firebase.messaging',
            $this->credentialsPath,
        );

        return $credentials->fetchAuthToken()['access_token'];
    }
}
