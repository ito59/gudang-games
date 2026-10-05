<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

/**
 * The app's heartbeat while it is in the foreground, and its goodbye when it
 * goes to the background — so a member who closes the app drops off the
 * "Online now" strip straight away instead of a few minutes later.
 */
class PresenceController extends Controller
{
    /** Being seen is done by [TrackPresence]; this only gives it a reason to run. */
    public function store(): Response
    {
        return response()->noContent();
    }

    public function destroy(Request $request): Response
    {
        $request->user()->markAway();

        return response()->noContent();
    }
}
