<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class MemberController extends Controller
{
    /** Powers the "Online now" strip. */
    public function index(Request $request): AnonymousResourceCollection
    {
        // By name so the guard is the token the app sends, not a session.
        $viewer = $request->user('sanctum');

        return UserResource::collection(
            User::where('is_active', true)
                // Blocked members leave the strip in both directions. Their
                // profile is still reachable by id, which is what makes the
                // block undoable.
                ->when($viewer?->hiddenUserIds(), fn ($q, $hidden) => $q->whereNotIn('id', $hidden))
                ->withFriendshipFor($viewer)
                // Online first, most recently seen first among them; the rest
                // fill the strip dimmed, alphabetically.
                ->orderByRaw('CASE WHEN last_seen_at > ? THEN 0 ELSE 1 END', [now()->subSeconds(User::ONLINE_WINDOW_SECONDS)])
                ->orderByDesc('last_seen_at')
                ->orderBy('name')
                ->take(20)
                ->get()
        );
    }

    /**
     * One member. The friendship state falls back to a single lookup here,
     * which is why this one does not eager-load the way the list does.
     */
    public function show(User $user): UserResource
    {
        return new UserResource($user);
    }
}
