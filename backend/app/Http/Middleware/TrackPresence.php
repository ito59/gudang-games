<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Any signed-in request is proof the member has the app open, so it counts
 * as being seen. Written at most every [User::PRESENCE_TOUCH_SECONDS] so a
 * screen that fires five calls at once costs one write, not five.
 */
class TrackPresence
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user instanceof User) {
            $user->markSeen();
        }

        return $next($request);
    }
}
