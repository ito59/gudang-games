@php
    $privacy = route('legal.privacy', ['lang' => $lang]);
    $terms = route('legal.terms', ['lang' => $lang]);
    $play = $legal['play_store_url'];

    // The app header's wordmark: "Games" in the brand red.
    $name = $legal['app_name'];
    $wordmark = str_ends_with($name, 'Games')
        ? e(substr($name, 0, -5)).'<span>Games</span>'
        : e($name);

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
    <meta name="theme-color" content="#d9bc80">
    <meta property="og:title" content="{{ $legal['app_name'] }}">
    <meta property="og:description" content="{{ $t['meta_description'] }}">
    <meta property="og:image" content="{{ asset('images/site/hero.jpg') }}">
    <meta property="og:type" content="website">
    <link rel="icon" type="image/png" href="{{ asset('images/site/logo-mark.png') }}">
    <link rel="alternate" hreflang="en" href="{{ url('/') }}?lang=en">
    <link rel="alternate" hreflang="id" href="{{ url('/') }}?lang=id">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;500;600;700&family=Sora:wght@600;700&display=swap" rel="stylesheet">
    <style>
        /* The app's cream-and-gold palette (lib/theme/app_colors.dart). */
        :root {
            --bg: #f7f1e5;
            --bg-deep: #efe6d4;
            --surface: #ffffff;
            --surface-2: #f5ebd6;
            --fill: #f4ecdc;
            --line: #ede3d0;
            --line-strong: #dccdb0;
            --text: #221c15;
            --muted: #6e6254;
            --red: #b3191e;
            --red-dark: #8f1217;
            --gold-light: #f3e4bf;
            --gold: #d9bc80;
            --gold-deep: #bf9a55;
            --on-gold: #2b2116;
            --gold-ink: #a9823d;
            --gold-band: linear-gradient(90deg, #d9bc80, #e6cf9c 50%, #f3e4bf);
            --gold-button: linear-gradient(90deg, #bf9a55, #d9bc80 50%, #f3e4bf);
            --shadow: 0 6px 18px rgba(90, 66, 32, .08);
            --radius: 18px;
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

        /* Nav: the app's gold header band with the white wordmark pill. */
        .nav { position: sticky; top: 0; z-index: 10; background: var(--gold-band); box-shadow: var(--shadow); }
        .nav .wrap { display: flex; align-items: center; gap: 24px; height: 68px; }
        .nav-logo { text-decoration: none; display: inline-flex; align-items: center; background: #fff; border-radius: 999px; padding: 6px 16px; font: 700 18px Sora, system-ui, sans-serif; letter-spacing: -.01em; color: var(--text); box-shadow: var(--shadow); white-space: nowrap; }
        .nav-logo span { color: var(--red); }
        .nav-links { display: none; gap: 24px; margin-left: auto; font-size: 15px; font-weight: 500; }
        .nav-links a { text-decoration: none; color: var(--on-gold); opacity: .78; }
        .nav-links a:hover { opacity: 1; }
        .lang { margin-left: auto; display: flex; gap: 2px; background: rgba(255, 255, 255, .7); border: 1px solid rgba(191, 154, 85, .4); border-radius: 999px; padding: 3px; font: 600 12px "Hanken Grotesk", system-ui, sans-serif; letter-spacing: .04em; }
        .lang a { text-decoration: none; padding: 5px 10px; border-radius: 999px; color: var(--muted); }
        .lang a[aria-current] { background: rgba(179, 25, 30, .1); color: var(--red); }
        @media (min-width: 820px) { .nav-links { display: flex; } .lang { margin-left: 0; } }

        /* Buttons: pills, gold gradient for the main action. */
        .btn { display: inline-flex; align-items: center; gap: 10px; padding: 14px 24px; border-radius: 999px; font-weight: 600; font-size: 16px; text-decoration: none; transition: transform .15s ease, box-shadow .15s ease, background .15s ease; }
        .btn:hover { transform: translateY(-1px); }
        .btn-primary { background: var(--gold-button); color: var(--on-gold); box-shadow: 0 10px 24px -10px rgba(143, 108, 47, .7); }
        .btn-primary:hover { box-shadow: 0 14px 28px -10px rgba(143, 108, 47, .8); }
        .btn-ghost { border: 1px solid var(--line-strong); background: var(--surface); color: var(--text); }
        .btn-ghost:hover { background: var(--fill); }
        .btn-soon { background: var(--surface-2); color: var(--muted); border: 1px dashed var(--line-strong); cursor: default; }
        .btn-soon:hover { transform: none; }
        .btn svg { width: 20px; height: 20px; flex: none; }

        /* Hero */
        .hero { position: relative; padding: 56px 0 72px; overflow: hidden; }
        .hero::before { content: ""; position: absolute; inset: 0; background: url("{{ asset('images/site/hero.jpg') }}") center / cover; opacity: .07; filter: grayscale(1) sepia(.6); mask-image: linear-gradient(180deg, #000 20%, transparent 95%); -webkit-mask-image: linear-gradient(180deg, #000 20%, transparent 95%); }
        .hero::after { content: ""; position: absolute; width: 640px; height: 640px; right: -180px; top: -120px; background: radial-gradient(circle, rgba(217, 188, 128, .55), transparent 65%); pointer-events: none; }
        .hero .wrap { position: relative; z-index: 1; display: grid; grid-template-columns: minmax(0, 1fr); gap: 48px; align-items: center; }
        .eyebrow { display: inline-flex; align-items: center; gap: 8px; font: 600 12px "Hanken Grotesk", system-ui, sans-serif; letter-spacing: .08em; text-transform: uppercase; color: var(--red); background: rgba(179, 25, 30, .08); border: 1px solid rgba(179, 25, 30, .18); padding: 6px 12px; border-radius: 999px; }
        .eyebrow::before { content: ""; width: 7px; height: 7px; border-radius: 50%; background: var(--red); }
        .hero h1 { font-size: clamp(40px, 7vw, 68px); margin: 20px 0 18px; color: var(--text); }
        .hero h1 span { color: var(--red); }
        .hero p.lede { font-size: 19px; color: var(--muted); max-width: 520px; margin: 0 0 30px; }
        .actions { display: flex; flex-wrap: wrap; gap: 12px; }
        .hero-phone { justify-self: center; }
        @media (min-width: 900px) {
            .hero { padding: 88px 0 104px; }
            .hero .wrap { grid-template-columns: minmax(0, 1.15fr) minmax(0, .85fr); }
        }

        /* Phone frame: the bronze bezel from the design. */
        .phone { width: 290px; max-width: 100%; border-radius: 42px; padding: 10px; background: linear-gradient(160deg, #8a6a3f, #3b2c1c); box-shadow: 0 40px 80px -30px rgba(90, 66, 32, .55), 0 0 0 1px rgba(191, 154, 85, .35); }
        .phone img { border-radius: 33px; width: 100%; aspect-ratio: 390 / 844; object-fit: cover; object-position: top; background: var(--bg-deep); }
        .tilt { transform: rotate(2.5deg); }

        /* Sections */
        section { padding: 80px 0; }
        .section-head { max-width: 640px; margin-bottom: 44px; }
        .section-head h2 { font-size: clamp(30px, 4.4vw, 44px); color: var(--text); }
        .section-head p { color: var(--muted); margin: 14px 0 0; font-size: 18px; }

        .features { display: grid; gap: 16px; grid-template-columns: minmax(0, 1fr); }
        @media (min-width: 640px) { .features { grid-template-columns: 1fr 1fr; } }
        @media (min-width: 980px) { .features { grid-template-columns: repeat(3, 1fr); } }
        .feature { background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); padding: 26px; box-shadow: var(--shadow); transition: border-color .2s ease, transform .2s ease; }
        .feature:hover { border-color: var(--gold); transform: translateY(-2px); }
        .feature .icon { width: 46px; height: 46px; border-radius: 14px; display: grid; place-items: center; background: var(--gold-light); color: var(--red); margin-bottom: 18px; }
        .feature .icon svg { width: 24px; height: 24px; fill: none; stroke: currentColor; stroke-width: 1.8; stroke-linecap: round; stroke-linejoin: round; }
        .feature:first-child .icon svg { fill: currentColor; stroke: none; }
        .feature h3 { font-size: 19px; margin-bottom: 8px; color: var(--text); }
        .feature p { margin: 0; color: var(--muted); font-size: 16px; }

        .showcase { background: linear-gradient(180deg, var(--bg), var(--bg-deep)); }
        .shots { display: grid; grid-template-columns: minmax(0, 1fr); gap: 56px; }
        .shot { display: grid; gap: 28px; justify-items: center; text-align: center; }
        .shot h3 { font-size: 22px; color: var(--text); margin-bottom: 8px; }
        .shot p { margin: 0 auto; color: var(--muted); max-width: 320px; }
        .shot .phone { width: 250px; }
        @media (min-width: 900px) {
            .shots { grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 32px; }
            .shot:nth-child(2) { margin-top: 56px; }
        }

        .games { display: grid; gap: 16px; grid-template-columns: repeat(2, minmax(0, 1fr)); }
        @media (min-width: 720px) { .games { grid-template-columns: repeat(4, 1fr); } }
        .game { background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); overflow: hidden; box-shadow: var(--shadow); }
        .game img { aspect-ratio: 1; width: 100%; object-fit: cover; background: var(--fill); }
        .game div { padding: 12px 14px 14px; }
        .game strong { display: block; font-family: Sora, sans-serif; font-size: 15px; color: var(--text); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .game span { font: 500 13px "Hanken Grotesk", system-ui, sans-serif; color: var(--muted); }

        .faq { display: grid; grid-template-columns: minmax(0, 1fr); gap: 12px; max-width: 780px; }
        details { background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); padding: 0 22px; box-shadow: var(--shadow); }
        summary { cursor: pointer; list-style: none; padding: 20px 0; font-weight: 600; display: flex; justify-content: space-between; gap: 16px; }
        summary::-webkit-details-marker { display: none; }
        summary::after { content: "+"; color: var(--gold-ink); font-size: 22px; line-height: 1; transition: transform .2s ease; }
        details[open] summary::after { transform: rotate(45deg); }
        details p { margin: 0 0 20px; color: var(--muted); }
        details a { color: var(--red); }

        .cta { text-align: center; }
        .cta-card { position: relative; overflow: hidden; border-radius: 28px; padding: 64px 24px; background: var(--gold-band); border: 1px solid rgba(191, 154, 85, .4); box-shadow: var(--shadow); }
        .cta-mark { display: inline-flex; margin: 0 auto 20px; background: #fff; border-radius: 999px; padding: 8px 20px; font: 700 22px Sora, system-ui, sans-serif; letter-spacing: -.01em; color: var(--text); box-shadow: var(--shadow); }
        .cta-mark span { color: var(--red); }
        .cta-card h2 { font-size: clamp(32px, 5vw, 48px); color: var(--on-gold); }
        .cta-card p { color: #5a4a35; margin: 12px 0 28px; font-size: 18px; }
        .cta .actions { justify-content: center; }
        .cta .btn-primary { background: var(--red); color: #fff; box-shadow: 0 10px 24px -10px rgba(143, 18, 23, .7); }
        .cta .btn-primary:hover { background: var(--red-dark); }
        .cta .btn-soon { background: rgba(255, 255, 255, .6); border-color: rgba(191, 154, 85, .6); color: #5a4a35; }

        footer { border-top: 1px solid var(--line-strong); padding: 36px 0 48px; color: var(--muted); font-size: 14px; }
        footer .wrap { display: flex; flex-wrap: wrap; gap: 16px 32px; align-items: center; justify-content: space-between; }
        footer nav { display: flex; flex-wrap: wrap; gap: 8px 22px; }
        footer a { text-decoration: none; }
        footer a:hover { color: var(--red); }

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
                {!! $wordmark !!}
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
                    <div class="cta-mark" aria-hidden="true">{!! $wordmark !!}</div>
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
