<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;

/**
 * The public pages come in English and Indonesian. An explicit ?lang= wins;
 * otherwise the browser's preference, and English when it names neither.
 */
trait PicksSiteLanguage
{
    protected function siteLanguage(Request $request): string
    {
        $languages = ['en', 'id'];

        return in_array($request->query('lang'), $languages, true)
            ? $request->query('lang')
            : $request->getPreferredLanguage($languages);
    }
}
