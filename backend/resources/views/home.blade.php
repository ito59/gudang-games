@php
    $privacy = route('legal.privacy', ['lang' => $lang]);
    $terms = route('legal.terms', ['lang' => $lang]);
    $play = $legal['play_store_url'];

    $icons = [
        'play' => '<path d="M8 5.5v13l10.5-6.5L8 5.5Z"/>',
        'spark' => '<path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5 18 18M18 6l-2.5 2.5M8.5 15.5 6 18"/>',
        'grid' => '<rect x="4" y="4" width="6.5" height="6.5" rx="1.5"/><rect x="13.5" y="4" width="6.5" height="6.5" rx="1.5"/><rect x="4" y="13.5" width="6.5" height="6.5" rx="1.5"/><rect x="13.5" y="13.5" width="6.5" height="6.5" rx="1.5"/>',
        'people' => '<circle cx="9" cy="8" r="3.2"/><path d="M3 19c.6-3.2 3-5 6-5s5.4 1.8 6 5"/><circle cx="17" cy="9" r="2.4"/><path d="M16.5 14.2c2.3.2 4 1.8 4.5 4.3"/>',
        'chat' => '<path d="M5 5h14a1.5 1.5 0 0 1 1.5 1.5v9A1.5 1.5 0 0 1 19 17h-8l-4.5 3.5V17H5a1.5 1.5 0 0 1-1.5-1.5v-9A1.5 1.5 0 0 1 5 5Z"/>',
        'shield' => '<path d="M12 3.5 19 6v5.5c0 4.3-2.9 7.6-7 9-4.1-1.4-7-4.7-7-9V6l7-2.5Z"/><path d="m9 12 2.2 2.2L15.5 10"/>',
    ];
@endphp
<!DOCTYPE html>
<html lang="{{ $lang }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $legal['app_name'] }}</title>
    <meta name="description" content="{{ $t['meta_description'] }}">
    <meta name="theme-color" content="#0b1326">
    <meta property="og:title" content="{{ $legal['app_name'] }}">
    <meta property="og:description" content="{{ $t['meta_description'] }}">
    <meta property="og:image" content="{{ asset('images/site/hero.jpg') }}">
    <meta property="og:type" content="website">
    <link rel="icon" type="image/png" href="{{ asset('images/site/logo-mark.png') }}">
    <link rel="alternate" hreflang="en" href="{{ url('/') }}?lang=en">
    <link rel="alternate" hreflang="id" href="{{ url('/') }}?lang=id">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;500;600&family=JetBrains+Mono:wght@500&family=Sora:wght@600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg: #0b1326;
            --bg-deep: #060e20;
            --surface: #131b2e;
            --surface-2: #171f33;
            --line: #2d3449;
            --text: #dae2fd;
            --muted: #a9a3bd;
            --primary: #d2bbff;
            --violet: #7c3aed;
            --cyan: #14d1ff;
            --pink: #ffb2ba;
            --radius: 20px;
        }
        * { box-sizing: border-box; }
        html { scroll-behavior: smooth; }
        body {
            margin: 0;
            background: var(--bg);
            color: var(--text);
            font: 17px/1.6 "Hanken Grotesk", system-ui, sans-serif;
            -webkit-font-smoothing: antialiased;
            overflow-x: hidden;
        }
        img { max-width: 100%; height: auto; display: block; }
        a { color: inherit; }
        h1, h2, h3 { font-family: Sora, system-ui, sans-serif; line-height: 1.12; margin: 0; letter-spacing: -.01em; }
        .wrap { width: 100%; max-width: 1160px; margin: 0 auto; padding: 0 16px; }
        @media (min-width: 720px) { .wrap { padding: 0 32px; } }

        /* Nav */
        .nav { position: sticky; top: 0; z-index: 10; background: rgba(11, 19, 38, .82); backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px); border-bottom: 1px solid rgba(45, 52, 73, .6); }
        .nav .wrap { display: flex; align-items: center; gap: 24px; height: 68px; }
        .nav-logo img { height: 36px; width: auto; }
        .nav-links { display: none; gap: 24px; margin-left: auto; font-size: 15px; }
        .nav-links a { text-decoration: none; color: var(--muted); }
        .nav-links a:hover { color: var(--text); }
        .lang { margin-left: auto; display: flex; gap: 2px; background: var(--surface); border: 1px solid var(--line); border-radius: 999px; padding: 3px; font: 500 12px "JetBrains Mono", monospace; }
        .lang a { text-decoration: none; padding: 5px 10px; border-radius: 999px; color: var(--muted); }
        .lang a[aria-current] { background: var(--violet); color: #fff; }
        @media (min-width: 820px) { .nav-links { display: flex; } .lang { margin-left: 0; } }

        /* Buttons */
        .btn { display: inline-flex; align-items: center; gap: 10px; padding: 14px 22px; border-radius: 14px; font-weight: 600; font-size: 16px; text-decoration: none; transition: transform .15s ease, background .15s ease; }
        .btn:hover { transform: translateY(-1px); }
        .btn-primary { background: var(--violet); color: #fff; box-shadow: 0 10px 30px -10px rgba(124, 58, 237, .8); }
        .btn-primary:hover { background: #8b4cf5; }
        .btn-ghost { border: 1px solid var(--line); color: var(--text); }
        .btn-ghost:hover { background: var(--surface); }
        .btn-soon { background: var(--surface-2); color: var(--muted); border: 1px dashed var(--line); cursor: default; }
        .btn-soon:hover { transform: none; }
        .btn svg { width: 20px; height: 20px; flex: none; }

        /* Hero */
        .hero { position: relative; padding: 56px 0 72px; overflow: hidden; }
        .hero::before { content: ""; position: absolute; inset: 0; background: url("{{ asset('images/site/hero.jpg') }}") center / cover; opacity: .16; mask-image: linear-gradient(180deg, #000 20%, transparent 95%); -webkit-mask-image: linear-gradient(180deg, #000 20%, transparent 95%); }
        .hero::after { content: ""; position: absolute; width: 640px; height: 640px; right: -180px; top: -120px; background: radial-gradient(circle, rgba(124, 58, 237, .45), transparent 65%); pointer-events: none; }
        .hero .wrap { position: relative; z-index: 1; display: grid; grid-template-columns: minmax(0, 1fr); gap: 48px; align-items: center; }
        .eyebrow { display: inline-flex; align-items: center; gap: 8px; font: 500 12px "JetBrains Mono", monospace; letter-spacing: .08em; text-transform: uppercase; color: var(--pink); background: rgba(205, 0, 71, .16); border: 1px solid rgba(255, 178, 186, .25); padding: 6px 12px; border-radius: 999px; }
        .eyebrow::before { content: ""; width: 7px; height: 7px; border-radius: 50%; background: var(--pink); }
        .hero h1 { font-size: clamp(40px, 7vw, 68px); margin: 20px 0 18px; color: #f1ecff; }
        .hero h1 span { background: linear-gradient(90deg, var(--primary), var(--cyan)); -webkit-background-clip: text; background-clip: text; color: transparent; }
        .hero p.lede { font-size: 19px; color: var(--muted); max-width: 520px; margin: 0 0 30px; }
        .actions { display: flex; flex-wrap: wrap; gap: 12px; }
        .hero-phone { justify-self: center; }
        @media (min-width: 900px) {
            .hero { padding: 88px 0 104px; }
            .hero .wrap { grid-template-columns: minmax(0, 1.15fr) minmax(0, .85fr); }
        }

        /* Phone frame */
        .phone { width: 290px; max-width: 100%; border-radius: 42px; padding: 10px; background: linear-gradient(160deg, #3a3150, #151b2e); box-shadow: 0 40px 80px -30px rgba(0, 0, 0, .8), 0 0 0 1px rgba(210, 187, 255, .12), 0 0 90px -20px rgba(124, 58, 237, .55); }
        .phone img { border-radius: 33px; width: 100%; aspect-ratio: 390 / 844; object-fit: cover; object-position: top; background: var(--bg-deep); }
        .tilt { transform: rotate(2.5deg); }

        /* Sections */
        section { padding: 80px 0; }
        .section-head { max-width: 640px; margin-bottom: 44px; }
        .section-head h2 { font-size: clamp(30px, 4.4vw, 44px); color: #f1ecff; }
        .section-head p { color: var(--muted); margin: 14px 0 0; font-size: 18px; }

        .features { display: grid; gap: 16px; grid-template-columns: minmax(0, 1fr); }
        @media (min-width: 640px) { .features { grid-template-columns: 1fr 1fr; } }
        @media (min-width: 980px) { .features { grid-template-columns: repeat(3, 1fr); } }
        .feature { background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); padding: 26px; transition: border-color .2s ease, transform .2s ease; }
        .feature:hover { border-color: rgba(210, 187, 255, .35); transform: translateY(-2px); }
        .feature .icon { width: 46px; height: 46px; border-radius: 14px; display: grid; place-items: center; background: rgba(124, 58, 237, .18); color: var(--primary); margin-bottom: 18px; }
        .feature .icon svg { width: 24px; height: 24px; fill: none; stroke: currentColor; stroke-width: 1.8; stroke-linecap: round; stroke-linejoin: round; }
        .feature:first-child .icon svg { fill: currentColor; stroke: none; }
        .feature h3 { font-size: 19px; margin-bottom: 8px; color: #f1ecff; }
        .feature p { margin: 0; color: var(--muted); font-size: 16px; }

        .showcase { background: linear-gradient(180deg, var(--bg), var(--bg-deep)); }
        .shots { display: grid; grid-template-columns: minmax(0, 1fr); gap: 56px; }
        .shot { display: grid; gap: 28px; justify-items: center; text-align: center; }
        .shot h3 { font-size: 22px; color: #f1ecff; margin-bottom: 8px; }
        .shot p { margin: 0 auto; color: var(--muted); max-width: 320px; }
        .shot .phone { width: 250px; }
        @media (min-width: 900px) {
            .shots { grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 32px; }
            .shot:nth-child(2) { margin-top: 56px; }
        }

        .games { display: grid; gap: 16px; grid-template-columns: repeat(2, minmax(0, 1fr)); }
        @media (min-width: 720px) { .games { grid-template-columns: repeat(4, 1fr); } }
        .game { background: var(--surface); border: 1px solid var(--line); border-radius: 16px; overflow: hidden; }
        .game img { aspect-ratio: 1; width: 100%; object-fit: cover; }
        .game div { padding: 12px 14px 14px; }
        .game strong { display: block; font-family: Sora, sans-serif; font-size: 15px; color: #f1ecff; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .game span { font: 500 12px "JetBrains Mono", monospace; color: var(--muted); }

        .faq { display: grid; grid-template-columns: minmax(0, 1fr); gap: 12px; max-width: 780px; }
        details { background: var(--surface); border: 1px solid var(--line); border-radius: 16px; padding: 0 22px; }
        summary { cursor: pointer; list-style: none; padding: 20px 0; font-weight: 600; display: flex; justify-content: space-between; gap: 16px; }
        summary::-webkit-details-marker { display: none; }
        summary::after { content: "+"; color: var(--primary); font-size: 22px; line-height: 1; transition: transform .2s ease; }
        details[open] summary::after { transform: rotate(45deg); }
        details p { margin: 0 0 20px; color: var(--muted); }
        details a { color: var(--primary); }

        .cta { text-align: center; }
        .cta-card { position: relative; overflow: hidden; border-radius: 28px; padding: 64px 24px; background: linear-gradient(135deg, #2a1459, #0f1a3a 60%, #062f3d); border: 1px solid rgba(210, 187, 255, .18); }
        .cta-card img { width: 64px; margin: 0 auto 20px; }
        .cta-card h2 { font-size: clamp(32px, 5vw, 48px); color: #fff; }
        .cta-card p { color: var(--muted); margin: 12px 0 28px; font-size: 18px; }
        .cta .actions { justify-content: center; }

        footer { border-top: 1px solid var(--line); padding: 36px 0 48px; color: var(--muted); font-size: 14px; }
        footer .wrap { display: flex; flex-wrap: wrap; gap: 16px 32px; align-items: center; justify-content: space-between; }
        footer nav { display: flex; flex-wrap: wrap; gap: 8px 22px; }
        footer a { text-decoration: none; }
        footer a:hover { color: var(--text); }

        @media (prefers-reduced-motion: reduce) {
            html { scroll-behavior: auto; }
            .btn, .feature { transition: none; }
        }
    </style>
</head>
<body>
{{-- Keeps Cloudflare from rewriting the contact address; see legal/layout. --}}
<!--email_off-->
    <header class="nav">
        <div class="wrap">
            <a class="nav-logo" href="{{ url('/') }}?lang={{ $lang }}" aria-label="{{ $legal['app_name'] }}">
                <img src="{{ asset('images/site/logo-lockup.png') }}" alt="{{ $legal['app_name'] }}" width="94" height="36">
            </a>
            <nav class="nav-links" aria-label="Sections">
                <a href="#features">{{ $t['nav_features'] }}</a>
                @if ($games->isNotEmpty())
                    <a href="#games">{{ $t['nav_games'] }}</a>
                @endif
                <a href="#faq">{{ $t['nav_faq'] }}</a>
            </nav>
            <div class="lang" role="group" aria-label="Language">
                <a href="?lang=en" hreflang="en" @if ($lang === 'en') aria-current="true" @endif>EN</a>
                <a href="?lang=id" hreflang="id" @if ($lang === 'id') aria-current="true" @endif>ID</a>
            </div>
        </div>
    </header>

    <main>
        <section class="hero">
            <div class="wrap">
                <div>
                    <span class="eyebrow">{{ $t['eyebrow'] }}</span>
                    <h1>{!! preg_replace('/(\S+\.)$/u', '<span>$1</span>', e($t['headline'])) !!}</h1>
                    <p class="lede">{{ $t['lede'] }}</p>
                    <div class="actions">
                        @include('partials.store-button')
                        <a class="btn btn-ghost" href="#features">{{ $t['secondary_cta'] }}</a>
                    </div>
                </div>
                <div class="hero-phone">
                    <div class="phone tilt">
                        <img src="{{ asset('images/site/screen-home.png') }}" alt="{{ $t['showcase'][0]['alt'] }}" width="390" height="844">
                    </div>
                </div>
            </div>
        </section>

        <section id="features">
            <div class="wrap">
                <div class="section-head">
                    <h2>{{ $t['features_title'] }}</h2>
                    <p>{{ $t['features_lede'] }}</p>
                </div>
                <div class="features">
                    @foreach ($t['features'] as $feature)
                        <article class="feature">
                            <div class="icon"><svg viewBox="0 0 24 24" aria-hidden="true">{!! $icons[$feature['icon']] !!}</svg></div>
                            <h3>{{ $feature['title'] }}</h3>
                            <p>{{ $feature['body'] }}</p>
                        </article>
                    @endforeach
                </div>
            </div>
        </section>

        <section class="showcase">
            <div class="wrap">
                <div class="shots">
                    @foreach ($t['showcase'] as $shot)
                        <figure class="shot" style="margin: 0">
                            <div class="phone">
                                <img src="{{ asset('images/site/'.$shot['image']) }}" alt="{{ $shot['alt'] }}" width="390" height="844" loading="lazy">
                            </div>
                            <figcaption>
                                <h3>{{ $shot['title'] }}</h3>
                                <p>{{ $shot['body'] }}</p>
                            </figcaption>
                        </figure>
                    @endforeach
                </div>
            </div>
        </section>

        @if ($games->isNotEmpty())
            <section id="games">
                <div class="wrap">
                    <div class="section-head">
                        <h2>{{ $t['games_title'] }}</h2>
                        <p>{{ $t['games_lede'] }}</p>
                    </div>
                    <div class="games">
                        @foreach ($games as $game)
                            <div class="game">
                                <img src="{{ $game->cover_url }}" alt="" loading="lazy">
                                <div>
                                    <strong>{{ $game->title }}</strong>
                                    <span>{{ $game->category?->name }}@if ($game->rating > 0) · ★ {{ number_format($game->rating, 1) }}@endif</span>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            </section>
        @endif

        <section id="faq">
            <div class="wrap">
                <div class="section-head">
                    <h2>{{ $t['faq_title'] }}</h2>
                </div>
                <div class="faq">
                    @foreach ($t['faq'] as $i => $item)
                        <details @if ($i === 0) open @endif>
                            <summary>{{ $item['q'] }}</summary>
                            <p>
                                {{ $item['a'] }}
                                @if ($loop->last)
                                    <a href="{{ $privacy }}#delete">{{ $t['footer_privacy'] }} →</a>
                                @endif
                            </p>
                        </details>
                    @endforeach
                </div>
            </div>
        </section>

        <section class="cta">
            <div class="wrap">
                <div class="cta-card">
                    <img src="{{ asset('images/site/logo-mark.png') }}" alt="" width="64" height="75">
                    <h2>{{ $t['cta_title'] }}</h2>
                    <p>{{ $t['cta_lede'] }}</p>
                    <div class="actions">
                        @include('partials.store-button')
                    </div>
                </div>
            </div>
        </section>
    </main>

    <footer>
        <div class="wrap">
            <div>© {{ date('Y') }} {{ $legal['operator'] }}</div>
            <nav aria-label="Legal">
                <a href="{{ $privacy }}">{{ $t['footer_privacy'] }}</a>
                <a href="{{ $terms }}">{{ $t['footer_terms'] }}</a>
                <a href="{{ $privacy }}#delete">{{ $t['footer_delete'] }}</a>
                <a href="mailto:{{ $contact }}">{{ $t['footer_contact'] }}</a>
            </nav>
        </div>
    </footer>
<!--/email_off-->
</body>
</html>
