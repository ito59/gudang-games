<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use App\Services\Push\Push;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * What a member wants to be told about, and where to tell them.
 *
 * The preference lives on the account rather than the phone: turning chat
 * notifications off on one device should not leave a tablet buzzing.
 */
class NotificationController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json(['data' => $this->settings($request)]);
    }

    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'chat' => ['sometimes', 'boolean'],
            'news' => ['sometimes', 'boolean'],
        ]);

        $user = $request->user();
        $user->update([
            'notify_chat' => $data['chat'] ?? $user->notify_chat,
            'notify_news' => $data['news'] ?? $user->notify_news,
        ]);

        return response()->json(['data' => $this->settings($request)]);
    }

    /** Records where this install can be reached. */
    public function registerDevice(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string', 'max:512'],
            'platform' => ['nullable', 'string', 'max:16'],
        ]);

        DeviceToken::remember($request->user(), $data['token'], $data['platform'] ?? null);

        return response()->json(['data' => $this->settings($request)]);
    }

    /**
     * Forgets this install — on sign-out, so the next person to use the phone
     * is not sent somebody else's messages.
     */
    public function forgetDevice(Request $request): JsonResponse
    {
        $data = $request->validate(['token' => ['required', 'string', 'max:512']]);

        DeviceToken::where('token_hash', DeviceToken::hash($data['token']))->delete();

        return response()->json(['data' => $this->settings($request)]);
    }

    /**
     * @return array<string, mixed>
     */
    private function settings(Request $request): array
    {
        $user = $request->user();

        return [
            'chat' => (bool) $user->notify_chat,
            'news' => (bool) $user->notify_news,
            // So the app can say why nothing arrives on a deployment with no
            // Firebase, rather than leaving somebody to wonder.
            'push_available' => app(Push::class)->isConfigured(),
            'news_topic' => (string) config('push.news_topic'),
        ];
    }
}
