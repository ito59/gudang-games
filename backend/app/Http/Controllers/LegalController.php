<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\PicksSiteLanguage;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\View\View;

/**
 * The privacy policy and terms, as public pages Play Console can link to.
 *
 * Plain Blade rather than Inertia: these have to render for a reviewer's
 * browser and for crawlers with no JavaScript and no asset build behind them.
 */
class LegalController extends Controller
{
    use PicksSiteLanguage;

    public function privacy(Request $request): View
    {
        return $this->page($request, 'privacy');
    }

    public function terms(Request $request): View
    {
        return $this->page($request, 'terms');
    }

    private function page(Request $request, string $document): View
    {
        $lang = $this->siteLanguage($request);

        // Carried through the page's own links, so moving between the policy
        // and the terms inside the app stays dark.
        $dark = $request->query('theme') === 'dark';
        $keep = ['lang' => $lang] + ($dark ? ['theme' => 'dark'] : []);

        $effective = Carbon::parse(config('legal.effective_date'))->locale($lang);

        return view("legal.{$document}.{$lang}", [
            'lang' => $lang,
            'dark' => $dark,
            'keep' => $keep,
            'document' => $document,
            'legal' => config('legal'),
            'contact' => config('legal.contact_email') ?: config('mail.from.address'),
            'effective' => $effective->translatedFormat('j F Y'),
        ]);
    }
}
