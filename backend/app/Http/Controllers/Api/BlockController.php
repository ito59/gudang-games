<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\Block;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Blocking, and the list of who is blocked.
 *
 * The person blocked is never told. They find out, if at all, by noticing
 * that a message will not send — which is the least the feature can leak and
 * still work at all.
 */
class BlockController extends Controller
{
    /** Who this member has blocked, so the list can be undone from settings. */
    public function index(Request $request): AnonymousResourceCollection
    {
        return UserResource::collection(
            $request->user()->blockedUsers()->orderBy('name')->get()
        );
    }

    public function store(Request $request, User $user): JsonResponse
    {
        $viewer = $request->user();

        abort_if($viewer->is($user), 422, 'You cannot block yourself.');

        // firstOrCreate rather than create: tapping Block twice, or on two
        // devices, is one block.
        Block::firstOrCreate([
            'user_id' => $viewer->id,
            'blocked_user_id' => $user->id,
        ]);

        // A block ends the friendship rather than leaving somebody on a list
        // of friends they cannot see or speak to.
        $viewer->friendshipWith($user)?->delete();

        return response()->json(['blocked' => true]);
    }

    public function destroy(Request $request, User $user): JsonResponse
    {
        $request->user()->blocks()->where('blocked_user_id', $user->id)->delete();

        // Unblocking restores reach, not the friendship — that was ended, and
        // quietly putting it back would surprise both of them.
        return response()->json(['blocked' => false]);
    }
}
