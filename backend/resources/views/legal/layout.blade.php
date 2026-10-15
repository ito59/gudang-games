<!DOCTYPE html>
<html lang="{{ $lang }}" @if ($dark) data-theme="dark" @endif>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title') · {{ $legal['app_name'] }}</title>
    <meta name="description" content="@yield('title') — {{ $legal['app_name'] }} ({{ $legal['operator'] }})">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;500;600;700&family=Sora:wght@600;700&display=swap" rel="stylesheet">
    <style>
        /* The app's cream-and-gold palette (lib/theme/app_colors.dart). */
        :root {
            color-scheme: light;
            --bg: #f7f1e5;
            --card: #ffffff;
            --surface: #f5ebd6;
            --text: #221c15;
            --muted: #6e6254;
            --line: #ede3d0;
            --accent: #b3191e;
            --gold-ink: #a9823d;
            --gold-band: linear-gradient(90deg, #d9bc80, #e6cf9c 50%, #f3e4bf);
        }
        /* The app may still ask for dark with ?theme=dark (an Android WebView
           reports light to the page whatever the app around it looks like),
           so that request gets a warm dark rather than the old violet. */
        :root[data-theme="dark"] {
            color-scheme: dark;
            --bg: #1c1610;
            --card: #261e16;
            --surface: #2e251b;
            --text: #f7f1e5;
            --muted: #c9bba3;
            --line: #3d3225;
            --accent: #e0a07a;
            --gold-ink: #d9bc80;
            --gold-band: linear-gradient(90deg, #6b5530, #7f6538 50%, #8f7444);
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            background: var(--bg);
            color: var(--text);
            font: 16px/1.65 "Hanken Grotesk", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
        }
        .wrap { max-width: 760px; margin: 0 auto; padding: 0 16px 64px; }
        header { background: var(--gold-band); margin: 0 -16px 28px; padding: 22px 16px 18px; border-radius: 0 0 24px 24px; box-shadow: 0 6px 18px rgba(90, 66, 32, .08); }
        @media (min-width: 792px) { header { margin: 0 0 28px; padding: 22px 24px 18px; } }
        .brand { display: inline-block; font: 700 17px Sora, system-ui, sans-serif; color: #221c15; background: #fff; padding: 6px 16px; border-radius: 999px; letter-spacing: -.01em; box-shadow: 0 6px 18px rgba(90, 66, 32, .08); }
        .brand span { color: #b3191e; }
        nav { display: flex; flex-wrap: wrap; gap: 8px 16px; align-items: center; margin-top: 12px; font-size: 14px; }
        nav .spacer { flex: 1; }
        nav a { color: #2b2116; opacity: .75; text-decoration: none; }
        nav a[aria-current] { opacity: 1; font-weight: 600; }
        h1 { font-family: Sora, system-ui, sans-serif; font-size: 30px; line-height: 1.2; margin: 20px 0 6px; }
        .meta { color: var(--muted); font-size: 14px; margin: 0; }
        h2 { font-family: Sora, system-ui, sans-serif; color: var(--gold-ink); font-size: 20px; margin: 36px 0 8px; scroll-margin-top: 16px; }
        h3 { font-size: 16px; margin: 20px 0 4px; }
        a { color: var(--accent); }
        ul { padding-left: 22px; }
        li { margin: 4px 0; }
        .summary { background: var(--card); border: 1px solid var(--line); border-radius: 18px; padding: 4px 20px; box-shadow: 0 6px 18px rgba(90, 66, 32, .08); }
        table { width: 100%; border-collapse: collapse; font-size: 15px; margin: 12px 0; }
        th, td { text-align: left; vertical-align: top; padding: 10px 8px; border-bottom: 1px solid var(--line); }
        th { background: var(--surface); font-size: 13px; text-transform: uppercase; letter-spacing: .04em; color: var(--muted); }
        .table-wrap { overflow-x: auto; }
        footer { margin-top: 48px; padding-top: 20px; border-top: 1px solid var(--line); color: var(--muted); font-size: 14px; }
    </style>
</head>
<body>
{{-- The contact address has to be readable in the app, whose WebView runs no
     JavaScript to undo Cloudflare's email obfuscation. --}}
<!--email_off-->
<div class="wrap">
    <header>
        {{-- The app header's wordmark: "Games" in the brand red. --}}
        <div class="brand">@if (str_ends_with($legal['app_name'], 'Games')){{ substr($legal['app_name'], 0, -5) }}<span>Games</span>@else{{ $legal['app_name'] }}@endif</div>
        <nav>
            <a href="{{ route('legal.privacy', $keep) }}" @if ($document === 'privacy') aria-current="page" @endif>
                {{ $lang === 'id' ? 'Kebijakan Privasi' : 'Privacy Policy' }}
            </a>
            <a href="{{ route('legal.terms', $keep) }}" @if ($document === 'terms') aria-current="page" @endif>
                {{ $lang === 'id' ? 'Ketentuan Layanan' : 'Terms of Service' }}
            </a>
            <span class="spacer"></span>
            <a href="{{ url()->current().'?'.http_build_query([...$keep, 'lang' => 'en']) }}" @if ($lang === 'en') aria-current="true" @endif hreflang="en">English</a>
            <a href="{{ url()->current().'?'.http_build_query([...$keep, 'lang' => 'id']) }}" @if ($lang === 'id') aria-current="true" @endif hreflang="id">Bahasa Indonesia</a>
        </nav>
        <h1>@yield('title')</h1>
        <p class="meta">
            {{ $lang === 'id' ? 'Berlaku sejak' : 'Effective' }} {{ $effective }}
        </p>
    </header>

    <main>
        @yield('content')
    </main>

    <footer>
        {{ $legal['app_name'] }} · {{ $legal['operator'] }} ·
        <a href="mailto:{{ $contact }}">{{ $contact }}</a>
    </footer>
</div>
<!--/email_off-->
</body>
</html>
