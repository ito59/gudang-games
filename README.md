# BandarGames

A game discovery app built with Flutter. The home screen is a port of
`code.html` (Tailwind mockup), with `screen.png` as the visual reference.

## Running

```sh
flutter run
```

### Talking to the backend

The Popular Games list comes from the Laravel API in `backend/`. Point the app
at it per build — the default is a LAN address, because `localhost` on a phone
means the phone, not the machine running the API:

```sh
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

Serve the API on all interfaces so the device can reach it
(`php artisan serve --host=0.0.0.0`), and keep `APP_URL` in `backend/.env`
matching that address — it is what builds the cover and play URLs the app
receives.

Three things that otherwise fail silently:

- **A release build has no network access by default.** Flutter declares
  `android.permission.INTERNET` only in the debug and profile manifests, so
  `src/main/AndroidManifest.xml` declares it too — without that, a release APK
  quietly shows the sample catalogue and nothing explains why.
- **Android blocks cleartext HTTP** from API 28 up. `res/xml/network_security_config.xml`
  permits it for local dev hosts only; everything else must be HTTPS.
- **An unreachable backend is not an empty one.** The app falls back to its
  bundled sample catalogue and says so on screen, so stale samples are never
  mistaken for live data.

`GameRepository` is injectable (`BandarGamesApp(gameRepository: …)`) and every
widget test passes a fake, so the suite never touches the network.

### Browsing by category

The category strip is a filter, not decoration. Categories come from
`/api/v1/categories`, so one added in the admin panel shows up without an app
release. Tapping filters the grid; tapping the active one clears it, so there
is always a way back without hunting for a "show all" control.

Matching is on `category_slug`, not the display name — a renamed category
would otherwise silently stop matching its own games. A category with no games
says so and offers a way out, rather than leaving a blank grid.

Backend icon names (`swords`, `magic_button`, …) map to the glyphs the app
bundles; anything unmapped falls back to a generic pad rather than rendering a
missing-glyph box.

### Library and play history

`PlayHistory` (a `ChangeNotifier` in `PlayHistoryScope`, matching the profile
and chat pattern) keeps what has been played, persisted with
`shared_preferences`. The Library lists it ranked by play count, ties broken by
whichever was played most recently, with the count and how long ago.

**This history is per device, not per account.** The app has no sign-in, so
"this user" means this installation. `games.plays_count` on the backend is the
*global* popularity figure and answers a different question. When accounts
arrive, move these counters behind the API and keep the local store as a cache.

Two things it survives on purpose: unreadable stored JSON (history resets
rather than crashing the app) and a game the backend later unpublishes — each
entry keeps a snapshot of the game, refreshed every time it is played.

### The game page

A card tap opens `GameDetailScreen`, not the game. Browsing and committing are
different intents: the page shows the poster, title, category, rating,
popularity and description, then offers **Play Game** and **Play Trailer**.

Popularity is `plays_count` on the backend, incremented through
`POST /api/v1/games/{slug}/play` when Play Game is pressed. The call is
deliberately not awaited — a failed count must never delay or block somebody
playing. Counting there rather than in the file server keeps asset requests
from inflating the number, and treats hosted and linked games alike.

### Trailers

A game whose backend record has a trailer shows a small **Trailer** pill on its
cover. It is a separate tap target from the card itself, so watching a trailer
never starts the game by accident. `TrailerScreen` uses `video_player` with a
scrubbable progress bar.

Like the game player, the controller is built defensively — a platform with no
video plugin shows a message rather than crashing.

### Playing a game

Tapping a card opens `GamePlayerScreen`, a full-screen WebView, so hosted
bundles and external links both play without leaving the app. It allows
landscape and hides the system chrome while a game runs, and restores both on
the way out. A game with no source says so rather than opening an empty player.

The controller is built inside a `try`, because `webview_flutter` has no
implementation on some targets (unit tests included) — the screen then shows a
message instead of crashing.

## Screens

`AppShell` owns the bottom navigation and swaps between four destinations,
keeping each tab's scroll position via `IndexedStack`.

- **Home** — hero carousel, category filter, popular games grid.
- **Library** — games this person has played, most played first.
- **Community** — online-now strip, filter chips, post feed with local likes;
  pushes **Messages** (conversation list) and **Chat**.
- **Profile** — identity, stats, settings menu; pushes **Edit Profile**.

## Chat

`ChatController` (in `ChatScope`, the same `InheritedNotifier` pattern as the
profile) owns every conversation, so a thread survives navigating away and back.

Tapping another player — in the online strip or on a post's author — opens
`showMemberSheet`, which offers **View profile** and **Message**. A tap does not
carry enough intent to jump straight into a chat. Choosing Message creates the
thread on first contact; choosing View profile opens `MemberProfileScreen`, the
read-only counterpart to the editable `ProfileScreen`.

There is no backend, so an incoming reply is faked on a `Timer` after
`ChatController.replyDelay`. Two things follow from that:

- The controller cancels pending timers in `dispose`, otherwise they fire on a
  disposed notifier and widget tests fail on teardown.
- `ChatController(..., autoReply: false)` turns the fake off. Goldens and any
  test that should not depend on a timer use it.

Timestamps are formatted by `lib/utils/time_format.dart` (24-hour clock,
`Today`/`Yesterday` separators) rather than pulling in `intl`.

The hero section is a `PageView` that advances every 5 seconds. Autoplay pauses
while a finger is on the slider, and is skipped entirely when the OS asks for
reduced motion.

Community members have no photos in the design, so `MemberAvatar` falls back to
tinted initials and only the signed-in user shows the bundled avatar. Likes are
held in the screen's state (`Set<String>` of post ids) rather than on the
immutable mock models — move them to a repository when posts come from a
backend.

Profile state lives in a `ProfileController` (`ChangeNotifier`) exposed through
`ProfileScope`, an `InheritedNotifier`. Edit Profile works on a copy and pops
the result, so backing out never mutates anything — and prompts before
discarding real changes. Swap the body of `ProfileController.save` for a
repository call when a backend exists.

## Moderation, reporting and blocking

Three separate things, deliberately. The filter stops what nobody should have
to see. Reporting asks a human to look. Blocking is one member deciding for
themselves, needing nobody's agreement.

### The filter runs on the server

`App\Services\Moderation\ContentModerator` is the one door everything a
member writes goes through — chat messages, posts and comments alike. It runs
in Laravel, never in the app, for the obvious reason: the app is a program on
somebody else's phone, and a filter that can be deleted is not a filter.

A refusal is a 422 with the reason under `body`, the same shape as a message
that was too long, so the app needed no second failure path — `ChatRepository`
passes the server's words straight to the composer. The rejected text stays in
the field to be edited rather than retyped, and nothing is stored, broadcast or
pushed.

Two checks, in order:

- **Profanity.** `config/moderation.php` holds the word list, matched as whole
  words against every reading `TextNormaliser` produces. Substring matching is
  how a filter ends up rejecting `class`, `Scunthorpe` and `bangsa tercinta`,
  so the normaliser does the work instead: case, accents, leetspeak, stretched
  letters (`koooontooool`), punctuation inside a word (`k.o.n.t.o.l`) and
  spelt-out letters (`k o n t o l`) all fold onto the same entry. Spaces are
  only removed from runs of single letters, never between words, because
  squashing every space invents words nobody wrote.

  Mild slang (`anjir`, `anjay`, `kampret`) is deliberately absent. Blocking it
  annoys people who were not being abusive and teaches them to work around the
  filter, which costs more than it saves.

- **Spam.** The shapes a word list cannot see: the same line twice, a burst no
  one types by hand, a wall of links, a wall of capitals, a long run of one
  character. Counters live in the cache, keyed per member *and* per context,
  so a busy conversation never uses up somebody's allowance for posting.

The sender is told that a word is not allowed, never which one — naming it is a
lesson in getting past the filter. Every refusal is written to
`moderation_events` with the text intact, because a filter nobody can audit is
a filter nobody can tune.

### Reporting

A long press on a chat message or a comment, and the **More** menu on a post or
a member's profile. `POST /api/v1/reports` takes a `type`, an id, a reason from
the list the server itself publishes at `/api/v1/report-reasons`, and an
optional note.

Reporting hides nothing. A report is one person's account, filed for an admin
to read; letting it remove content would hand every member a way to silence
anyone they disagreed with. Three details that matter:

- A message can only be reported from inside its own thread. A guessed id
  answers 403 rather than confirming the message exists and handing over its
  text in the report excerpt.
- The report stores its own `excerpt`. The content may be deleted — by its
  author, or by the admin acting on this very report — and a queue that cannot
  say what it was about is unreviewable.
- Reporting the same thing twice is answered as success and files one row. The
  reporter did what they meant to, and an error only invites them to try again.

### Blocking

`POST`/`DELETE /api/v1/members/{user}/block`. The record is one-directional;
the effect is not. The blocked member cannot reach the blocker either, because
anything less leaves them talking into a room the other can no longer see.
Posts, comments, the online strip and the conversation list are all filtered in
both directions, and the block ends the friendship rather than leaving somebody
on a list of friends they cannot speak to.

The blocked member is never told. They are not told in the API either: a
profile reports whether *you* blocked *them*, never the reverse.

Because it is that quiet, `BlockedAccountsScreen` (Profile → Blocked accounts)
exists: a decision with no visible record is one nobody can revisit. Unblocking
restores reach — nothing was deleted — but not the friendship, which was ended
and should not reappear by surprise.

### The queue

Admin → **Reports**, in two tabs: what members reported, and what the filter
refused. They sit together because they answer each other — a member with three
reports and forty filter hits is a different problem from one with three
reports and none.

An admin dismisses, deletes the content, or suspends the member. Dismissing is
a first-class outcome, not giving up: most of what lands in a queue like this
is a disagreement rather than a breach, and recording that keeps the next admin
from re-reading it. Deleting content closes every other pending report of the
same thing. Members are suspended, never deleted, and an administrator can only
be suspended from the Users page, which has the last-administrator guard.

## Theming the Material defaults

Material 3 derives SnackBars and some overlays from `colorScheme.inverseSurface`,
which is a **light** colour in a dark scheme — an unthemed SnackBar renders as a
white slab over this UI. `AppTheme.dark` therefore sets `snackBarTheme`,
`dialogTheme`, `textButtonTheme` and `textSelectionTheme` explicitly, and
`test/golden_overlays_test.dart` pins the result.

The Android system bars are a separate surface again: `SystemUiOverlayStyle.light`
hard-codes `systemNavigationBarColor` to opaque black. `main()` opts into
`SystemUiMode.edgeToEdge` with transparent bars, and — because the generated
`LaunchTheme`/`NormalTheme` inherit from the legacy `Theme.Black.NoTitleBar`,
which does not let the window paint its own bar backgrounds — both
`res/values/styles.xml` and `res/values-night/styles.xml` add:

```xml
<item name="android:windowDrawsSystemBarBackgrounds">true</item>
<item name="android:statusBarColor">@android:color/transparent</item>
<item name="android:navigationBarColor">@android:color/transparent</item>
```

Without that XML the Dart-side colour is ignored and the platform paints the
navigation bar black.

## Text scaling

Layout must survive the OS font-size setting. `test/text_scale_test.dart`
walks every screen at 100–200% and fails on any `RenderFlex` overflow.

Two rules keep it that way:

- Never hard-code a height that equals the sum of text children. The popular
  games grid asks `GameCard.extentFor(context)`, which derives the height from
  the real text styles and the current `TextScaler`.
- The hero is a fixed height because a `PageView` needs one, so
  `FeaturedCard.heightFor(context)` grows it with the text scale (clamped), and
  the headline is capped at three lines. Its content is bottom-anchored in a
  `Stack`, which overflows *silently* — no error, just clipping.

## Brand assets

The supplied logo artwork has **no alpha channel** — the "transparency"
checkerboard is painted into the RGB pixels. `tool/extract_logo.py` recovers
the logo by reconstructing that checker analytically (including its
anti-aliased cell borders, which a hard two-level model turns into a grid of
ghost lines) and un-premultiplying the result.

```sh
tool/extract_logo.py <source.png> assets/brand/logo.png
tool/generate_icons.py
```

That produces three variants and every platform icon:

| Asset | Used for |
| --- | --- |
| `assets/brand/logo.png` | full lockup with its neon frame |
| `assets/brand/logo_lockup.png` | frameless G + wordmark — the app header |
| `assets/brand/logo_mark.png` | the G alone — every launcher/app icon |

The wordmark cannot survive a 48dp launcher icon, so the icons use the mark
only, on the `#0B1326` brand background with a soft violet bloom. Generated:
Android legacy mipmaps, adaptive foreground/background, a monochrome layer for
Android 13+ themed icons, the full iOS `AppIcon` set (flattened — iOS icons
must not carry alpha), and the web icons plus favicon.

### Splash

The Android splash was `@android:color/white`, which flashed a bright screen
before the dark UI. Fixing it takes **two** changes, because Android 12 changed
how the splash works:

- **Below API 31** the splash is `drawable/launch_background.xml` — brand colour
  plus a centred bitmap.
- **API 31+** the platform SplashScreen API draws it instead. It takes only the
  *colour* from `windowBackground` and ignores that drawable's bitmap layer, so
  the logo has to be declared separately in `values-v31/styles.xml` via
  `android:windowSplashScreenAnimatedIcon` (pointing at `drawable/splash_icon`,
  sized for the 288dp splash canvas) and `android:windowSplashScreenBackground`.
  Without the v31 override the startup screen comes up empty.

Note that `values-v31` *replaces* the theme from `values`, so it has to repeat
the system-bar items too.

## Design source

Everything visual traces back to `code.html`:

| Source | Ported to |
| --- | --- |
| Tailwind `colors` (M3 tokens) | `lib/theme/app_colors.dart` |
| Tailwind `fontSize` scale | `lib/theme/app_text_styles.dart` |
| Tailwind `spacing` / `borderRadius` | constants in `lib/theme/app_theme.dart` |
| `.glass-panel`, `.neon-glow` | `lib/widgets/glass_panel.dart` |
| Material Symbols glyphs | `lib/theme/app_icons.dart` |

Fonts (Sora, Hanken Grotesk, JetBrains Mono) and the five artwork images are
bundled under `assets/`, so the app renders identically offline.

`assets/fonts/MaterialSymbolsOutlined.ttf` is the full variable font (10.6 MB)
because the design needs glyphs Flutter's built-in Material Icons lacks
(`swords`, `magic_button`, `chess`) and the `FILL` axis that `Icon(fill: 1)`
drives. Only the glyphs actually referenced ship in the app — the icon
tree-shaker cuts it to ~35 KB — so keep `AppIcons` entries `const`.

## Release builds

Use an App Bundle for Play Store delivery, and split APKs only for direct
distribution (sideload, internal QA):

```sh
# Play Store
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols

# Direct distribution, one APK per ABI
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols
```

`--split-debug-info` moves Dart symbols out of the binary and `--obfuscate`
renames identifiers. Keep the `build/symbols` output for each release — it is
required to turn a crash report back into a readable stack trace:

```sh
flutter symbolize -i <stack_trace.txt> -d build/symbols/app.android-arm64.symbols
```

### What is already enabled

The Flutter Gradle plugin turns on R8 code shrinking and resource shrinking for
release builds by default, and icon fonts are tree-shaken automatically
(~99.8% off `MaterialIcons-Regular.otf`). There is no need to set
`isMinifyEnabled` in `android/app/build.gradle.kts` — doing so applies the
ProGuard file list twice. Add app-specific keep rules to
`android/app/proguard-rules.pro` and the plugin will pick the file up.

### Size reference

Measured on Flutter 3.44.7, arm64, release:

| Artifact | Size |
| --- | --- |
| APK (arm64) | 16.9 MB |
| Play download, arm64 device | ~7 MB |

Bundled assets account for ~1 MB of that: images 628 KB, text fonts 354 KB,
tree-shaken icon font 35 KB. The `cupertino_icons` dependency was removed —
it was shipping a 257 KB font the app never used.

The APK is larger than the download because native libraries ship
**uncompressed** — that is what 16 KB page support requires (see below).
Play compresses them for transfer, so `libflutter.so` + `libapp.so` go from
14.8 MB on disk to ~6.5 MB over the wire. Do not enable
`useLegacyPackaging` to shrink the APK: it re-compresses the libraries and
breaks 16 KB compatibility.

## 16 KB memory page support

Google Play requires apps targeting Android 15+ to work on devices with 16 KB
memory pages. This build satisfies all three requirements:

1. native libraries are stored uncompressed and 16 KB aligned in the archive
2. every ELF `LOAD` segment is aligned to 64 KB (a multiple of 16 KB)
3. the manifest declares `extractNativeLibs="false"`

These come from the toolchain defaults (AGP 9.0.1, NDK 28.2, `minSdk` 24) plus
the pinned `packaging.jniLibs.useLegacyPackaging = false` in
`android/app/build.gradle.kts`, which is there so the setting cannot regress.

Verify any release APK:

```sh
flutter build apk --release --target-platform android-arm64
tool/check_16kb.sh
```

The script exits non-zero and prints which library failed if compatibility is
ever lost.
