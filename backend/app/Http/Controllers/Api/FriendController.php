<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\Friendship;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class FriendController extends Controller
{
    /** Requests waiting on the signed-in member, newest first. */
    public function index(Request $request): AnonymousResourceCollection
    {
        $viewer = $request->user();

        $users = User::query()
            ->whereHas('sentFriendships', fn ($q) => $q
                ->where('friend_id', $viewer->id)
                ->where('status', Friendship::pending))
            ->withFriendshipFor($viewer)
            ->latest('id')
            ->get();

        return UserResource::collection($users);
    }

    /**
     * Asks to be friends.
     *
     * Asking somebody who has already asked you accepts their request instead
     * of opening a second one — two people tapping the same button should end
     * up friends, not deadlocked.
     */
    public function store(Request $request, User $user): JsonResponse
    {
        $viewer = $request->user();
        abort_if($viewer->is($user), 422, 'You cannot befriend yourself.');

        $existing = $viewer->friendshipWith($user);

        if ($existing === null) {
            Friendship::create([
                'user_id' => $viewer->id,
                'friend_id' => $user->id,
                'status' => Friendship::pending,
            ]);
        } elseif (! $existing->isAccepted() && $existing->friend_id === $viewer->id) {
            $existing->update([
                'status' => Friendship::accepted,
                'accepted_at' => now(),
            ]);
        }

        return $this->state($request, $user);
    }

    /** Accepts the request this member sent the signed-in one. */
    public function accept(Request $request, User $user): JsonResponse
    {
        $viewer = $request->user();

        $row = Friendship::query()
            ->where('user_id', $user->id)
            ->where('friend_id', $viewer->id)
            ->where('status', Friendship::pending)
            ->first();

        abort_if($row === null, 404, 'No request from that member.');

        $row->update(['status' => Friendship::accepted, 'accepted_at' => now()]);

        return $this->state($request, $user);
    }

    /**
     * Withdraws the connection, whichever stage it is at: cancels a request
     * the viewer sent, declines one they received, or unfriends.
     */
    public function destroy(Request $request, User $user): JsonResponse
    {
        $request->user()->friendshipWith($user)?->delete();

        return $this->state($request, $user);
    }

    /** Answers every friend call the same way: where the pair now stands. */
    private function state(Request $request, User $user): JsonResponse
    {
        return response()->json([
            'friendship' => $user->fresh()->friendshipStateFor($request->user()),
        ]);
    }
}
