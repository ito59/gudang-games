<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\PicksSiteLanguage;
use App\Models\Game;
use Illuminate\Http\Request;
use Illuminate\View\View;

/**
 * The public landing page that tells people what the app is and where to get
 * it. The admin panel lives at /admin.
 */
class HomeController extends Controller
{
    use PicksSiteLanguage;

    public function __invoke(Request $request): View
    {
        $lang = $this->siteLanguage($request);

        // Real covers only: games seeded from the Flutter bundle have no URL
        // the browser can load, and a grid of blanks sells nothing.
        $games = Game::published()
            ->with('category:id,name')
            ->whereNotNull('cover_path')
            ->where('cover_path', 'not like', 'assets/%')
            ->orderBy('sort_order')
            ->limit(8)
            ->get(['id', 'title', 'slug', 'category_id', 'cover_path', 'rating']);

        return view('home', [
            'lang' => $lang,
            't' => trans('landing', [], $lang),
            'legal' => config('legal'),
            'contact' => config('legal.contact_email') ?: config('mail.from.address'),
            'games' => $games,
        ]);
    }
}
