<!DOCTYPE html>
<html lang="{{ $lang }}" @if ($dark) data-theme="dark" @endif>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title') · {{ $legal['app_name'] }}</title>
    <meta name="description" content="@yield('title') — {{ $legal['app_name'] }} ({{ $legal['operator'] }})">
    <style>
        :root {
            color-scheme: light dark;
            --bg: #ffffff;
            --surface: #f5f3ff;
            --text: #1e1b2e;
            --muted: #5b5870;
            --line: #e4e1ee;
            --accent: #6d28d9;
        }
        @media (prefers-color-scheme: dark) {
            :root {
                --bg: #0b1020;
                --surface: #151b30;
                --text: #e7e5f0;
                --muted: #a09cb5;
                --line: #252c45;
                --accent: #b794f6;
            }
        }
        /* The app asks for dark with ?theme=dark: an Android WebView reports
           light to the page whatever the app around it looks like. */
        :root[data-theme="dark"] {
            color-scheme: dark;
            --bg: #0b1326;
            --surface: #151b30;
            --text: #e7e5f0;
            --muted: #a09cb5;
            --line: #252c45;
            --accent: #b794f6;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            background: var(--bg);
            color: var(--text);
            font: 16px/1.65 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
        }
        .wrap { max-width: 760px; margin: 0 auto; padding: 32px 16px 64px; }
        header { border-bottom: 1px solid var(--line); padding-bottom: 20px; margin-bottom: 28px; }
        .brand { font-weight: 700; color: var(--accent); letter-spacing: .01em; }
        nav { display: flex; flex-wrap: wrap; gap: 8px 16px; align-items: center; margin-top: 12px; font-size: 14px; }
        nav .spacer { flex: 1; }
        nav a { color: var(--muted); text-decoration: none; }
        nav a[aria-current] { color: var(--text); font-weight: 600; }
        h1 { font-size: 30px; line-height: 1.2; margin: 20px 0 6px; }
        .meta { color: var(--muted); font-size: 14px; margin: 0; }
        h2 { font-size: 20px; margin: 36px 0 8px; scroll-margin-top: 16px; }
        h3 { font-size: 16px; margin: 20px 0 4px; }
        a { color: var(--accent); }
        ul { padding-left: 22px; }
        li { margin: 4px 0; }
        .summary { background: var(--surface); border: 1px solid var(--line); border-radius: 12px; padding: 4px 20px; }
        table { width: 100%; border-collapse: collapse; font-size: 15px; margin: 12px 0; }
        th, td { text-align: left; vertical-align: top; padding: 10px 8px; border-bottom: 1px solid var(--line); }
        th { font-size: 13px; text-transform: uppercase; letter-spacing: .04em; color: var(--muted); }
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
        <div class="brand">{{ $legal['app_name'] }}</div>
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
