<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Gate for the admin panel. Signed-in members without the flag get a 403
 * rather than a redirect, so a missing permission is never mistaken for a
 * missing session.
 */
class EnsureUserIsAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        abort_unless($request->user()?->is_admin, 403, 'Admin access required.');

        return $next($request);
    }
}
