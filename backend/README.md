# GudangGames — backend

Laravel 12 + Inertia + Vue 3 admin panel, plus a REST API for the Flutter app
in the parent directory.

## Running

```sh
composer install
npm install
cp .env.example .env && php artisan key:generate   # first time only
php artisan migrate --seed
npm run build          # or: npm run dev
php artisan serve
php artisan reverb:start   # in a second shell, for chat
```

Chat is realtime, so the WebSocket server has to be running alongside
`php artisan serve`. Without it everything else works and messages simply
never arrive on their own.

### Database

MySQL. Create the schema once, then migrate:

```sql
CREATE DATABASE bandar_games CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

`.env` defaults to `127.0.0.1:3306`, user `root`, empty password. The test
suite runs against an in-memory SQLite database (see `phpunit.xml`), so
`php artisan test` never touches your MySQL data.

#### On MySQL older than 5.5.3

That version predates `utf8mb4`, and the connection fails with *Unknown
character set: 'utf8mb4'* before any query runs. Set both in `.env`:

```env
DB_CHARSET=utf8
DB_COLLATION=utf8_general_ci
```

Then `php artisan config:clear`, since a cached config keeps the old value.

Know what this costs: MySQL's `utf8` stores three bytes per character, so a
four-byte character — every emoji — is rejected with *Incorrect string value*
and the row is not written at all. In a chat app somebody will send one. The
real fix is a newer MySQL; this is how to run until then.

A server that old also has no window functions, and Eloquent quietly emits
SQL it cannot run. `with(['messages' => fn ($q) => $q->limit(1)])` becomes
session variables and a `HAVING` on a non-grouping field, answered with
*1463: non-grouping field used in HAVING clause*. Use a `latestOfMany()`
relation instead, which resolves to a plain `max(id)` subquery.

The test suite runs on SQLite, which executes both happily — so this class
of bug reaches production green. `ChatQueryShapeTest` asserts the generated
SQL carries no session variables, `HAVING`, or window functions.

### Uploads

Covers are stored on the `public` disk, so the symlink has to exist:

```sh
php artisan storage:link
```

`APP_URL` must match the host actually serving the app — it is what builds the
image URLs the admin panel and the API hand out. Left at the default
`http://localhost`, the API returns links a phone cannot open.

Seeded administrator: `admin@bandargames.test` / `password`.
The other seeded members share that password.

## Administrators

```sh
php artisan admin:create
```

Prompts for name, username, email and password — the password is never
echoed. An email that already belongs to a member promotes them instead of
failing. Non-interactive:

```sh
php artisan admin:create --name="Ito" --username=ito \
    --email=ito@example.com --password='...'
```

Passwords must be at least 12 characters with letters and numbers: this
account edits every game, member and post, so a guessable one is the whole
panel.

From the panel, **Members → New account** opens the same thing with a form.
Creating asks only for name, username, email and password, plus the two
flags — the profile fields have defaults and are editable the moment the
account exists.

The first administrator has to come from the command line, since there is
nobody to sign in as yet. After that either way works.

Members without the flag are refused every `/admin` route with a 403 rather
than a redirect, so a missing permission is never mistaken for a missing
session. `DashboardAccessTest` walks every admin route to check it, which is
what catches a route added to the group later without the middleware.

## Admin panel

Everything lives under `/admin` behind `auth` + the `admin` middleware, which
403s a signed-in member who is not an administrator rather than redirecting —
a missing permission should not look like a missing session.

| Screen | What it manages |
| --- | --- |
| Dashboard | counts, latest feed activity |
| Games | full CRUD, search, category filter, cover upload; the "featured" flag puts a game in the app's home carousel |
| Categories | inline CRUD; deleting one leaves its games uncategorised |
| User feed | moderate posts — edit, hide/publish, delete, filter by kind |
| Users | edit profile and stats, promote/suspend, delete |
| Reports | what members reported, and what the filter refused |

Two guards worth knowing about: an admin cannot delete their own account, and
the **last** administrator can neither be demoted nor deleted — otherwise the
panel locks everybody out.

## API (`/api/v1`)

Reads are public so the app can render before anyone signs in. Writes need a
Sanctum token from `POST /login`.

```
POST   /api/v1/login              email, password, device_name -> token
GET    /api/v1/categories
GET    /api/v1/games              published only
GET    /api/v1/featured           published only
GET    /api/v1/members            online first
GET    /api/v1/members/{user}
GET    /api/v1/feed               ?kind=clip|squad|update
GET    /api/v1/me                 (token)
POST   /api/v1/logout             (token)
POST   /api/v1/feed               (token) body, kind, game_id
POST   /api/v1/feed/{post}/like   (token)
DELETE /api/v1/feed/{post}/like   (token)
GET    /api/v1/conversations      (token) threads, newest first
POST   /api/v1/conversations      (token) user_id -> the thread with them
GET    /api/v1/conversations/{c}/messages   (token)
POST   /api/v1/conversations/{c}/messages   (token) body
POST   /api/v1/conversations/{c}/read       (token)
GET    /api/v1/report-reasons     the list the app shows
POST   /api/v1/reports            (token) type, id, reason, note
GET    /api/v1/me/blocks          (token)
POST   /api/v1/members/{user}/block    (token)
DELETE /api/v1/members/{user}/block    (token)
```

Likes are rows in `post_likes` with a unique index on `(post_id, user_id)`, so
liking twice cannot double count. `liked_by_me` is resolved with a single
`withExists` query and is always `false` for anonymous callers.

## Push notifications

Chat messages and admin news can reach a phone that is not open. Both are on
by default and switched per member in the app under Profile → Notifications;
the preference lives on the account, so turning chat off on a phone does not
leave a tablet buzzing.

Nothing here needs Firebase to run. `App\Services\Push\Push` is an
interface: with credentials it is `FcmPush`, without them it is `LogPush`,
which writes what it would have sent. A deployment with no Firebase still
sends messages and publishes news — the phones simply do not buzz, and each
skipped notification is a log line rather than silence. `/me/notifications`
reports `push_available` so the app can say so plainly.

To turn it on:

```env
FCM_PROJECT_ID=your-firebase-project-id
FCM_CREDENTIALS=/absolute/path/to/service-account.json
```

The JSON comes from Firebase Console → Project settings → Service accounts.
**Keep it out of the repository**: it can send a notification to every
install. `google/auth` — already here for Google sign-in — exchanges it for
the access token, so there is no new dependency.

Chat goes to the recipient's registered devices; news goes to a topic, which
is one call however many installs are subscribed. A member who turns news off
unsubscribes their own device from the topic.

News is announced only when it crosses into being published, so fixing a typo
in this morning's article does not buzz everybody again.

## Chat

One-to-one threads, kept live over WebSockets.

A pair only ever has one thread: `conversations.pair_key` holds `"<lower
id>:<higher id>"` under a unique index, so two devices tapping Message at the
same moment cannot open two. Participants live in a pivot rather than in two
columns, which is what would let group threads arrive later without reshaping
anything.

Unread is counted from `conversation_user.last_read_message_id`, not a
timestamp: a message sent in the same second as a read would be swallowed by a
`created_at >` comparison.

`MessageSent` is a `ShouldBroadcastNow` event on the private channel
`conversation.{id}`, authorised in `routes/channels.php` — only the two
participants may listen, which is the only thing standing between a signed-in
member and somebody else's messages. It is deliberately not the queued
`ShouldBroadcast`: with no worker running, a queued message never arrives.

Sends carry the client's `X-Socket-ID`, and the broadcast is `toOthers()`, so
the sender is not echoed its own message on top of the one already on screen.

The app is handed the socket's key, host and port by `GET /api/v1/config`, the
same way it is handed the Google client ID — configured once, on the server.
Private channels are authorised at `POST /api/broadcasting/auth`, which is
behind `auth:sanctum` rather than the session guard.

## Moderation

Everything a member writes — chat, posts, comments — goes through
`ContentModerator` before it is stored. It runs here rather than in the app
because the app is a program on somebody else's phone; a filter that can be
deleted is not a filter.

A refusal is a `ValidationException`, so it answers 422 with the reason under
`body` — the same shape the app already handles for a message that was too
long. Nothing rejected is stored, broadcast or pushed, and every rejection is
written to `moderation_events` with the text intact: a filter nobody can audit
is a filter nobody can tune.

`config/moderation.php` holds both lists and every threshold, so tuning the
filter is a config change rather than a deploy of new code.
`MODERATION_ENABLED=false` turns it off for local work.

### Matching words people misspell on purpose

The word list is matched **whole-word**, against every reading
`TextNormaliser` produces. Substring matching is how a filter comes to reject
`class`, `Scunthorpe` and `bangsa tercinta`.

Each variant folds one evasion: leetspeak (`k0nt0l`), stretched letters
(`koooontooool`), punctuation inside a word (`k.o.n.t.o.l`), letters spelt out
(`k o n t o l`). Two rules keep the aggressive folds from inventing words:

- Symbols become letters only when a letter or digit follows, so `sh!t` folds
  and the `!` in `nice shot!` does not.
- Spaces are removed only from runs of single letters. Squashing every space
  turns `bangsa tercinta` into something containing `bangsat`.

Consonant-only spellings (`kntl`, `fck`) are list entries of their own:
dropping vowels is the commonest way past a word list, and catching it
generally would flag far too much ordinary text.

### Spam

What a word list cannot see: the same line twice, a burst nobody types by
hand, too many links, shouting, a long run of one character. The counters live
in the cache, keyed per member and per context — a long conversation must not
use up somebody's allowance for posting. They describe the last few seconds
and are worthless a minute later, so a cache flush costs nothing.

## Reports and blocks

Two different powers. A report asks a human to look; a block is one member
deciding for themselves and needing nobody's agreement.

`reports` is polymorphic over messages, posts, comments and members, with a
unique index on `(reporter, target)` — reporting twice is impatience, not new
information, and is answered as success so nobody is invited to retry. Each row
keeps its own `excerpt`, because the content may be gone by the time an admin
reads it. A message is only reportable from inside its own thread: a guessed id
answers 403 rather than handing back its text in the excerpt.

Nothing is hidden because it was reported. Letting a report remove content
would hand every member a way to silence anyone they disagreed with.

A `blocks` row is one-directional; its effect is not. The blocked member cannot
reach the blocker either — anything less leaves them writing into a thread the
other can no longer read. Feeds, comments, the member list and the conversation
list all filter on `User::hiddenUserIds()`, which is memoised per request
because several resources ask for it in turn. Blocking also ends the
friendship; unblocking restores reach but not the friendship.

The blocked member is never told, and the API does not leak it: a profile
reports whether the *viewer* blocked that member, never the reverse.

Admin → **Reports** reviews both the queue and what the filter refused, in two
tabs, because a member with three reports and forty filter hits is a different
problem from one with three reports and none. An admin dismisses, deletes the
content (which closes every other pending report of the same thing), or
suspends the member. Administrators can only be suspended from the Users page,
which has the last-administrator guard.

## Game source: URL or hosted ZIP

Every game declares how it is delivered:

- **External URL** — `game_url`, opened by the app. Nothing is hosted here.
- **Upload ZIP** — an HTML5 bundle extracted into **protected** storage,
  `storage/app/private/games/{slug}/`, and streamed by `GamePlayController`.

`Game::play_url` resolves either one, so callers never branch on the type.
Switching a game from ZIP to URL deletes the extracted bundle, and deleting a
game deletes it too.

### Bundles are not web-served

Nothing in a bundle sits under `public/`. Every byte goes through
`GET /games/{slug}/play/{path?}`, which means:

- **Drafts stay private.** An unpublished game 404s for the public and for
  ordinary members; only an administrator can preview it. On the public disk
  anyone with the URL could have read it.
- **The path in the URL is untrusted too.** `..`, absolute paths and stream
  wrappers are rejected, and the resolved real path must still sit inside the
  bundle root — so a symlink inside a bundle cannot point out of it either.
- **Correct content types.** Guessing from the file gives JavaScript
  `text/plain`, which breaks module scripts, and WebAssembly needs
  `application/wasm` for streaming compilation, so the types are mapped
  explicitly.

Tightening this further — say, members only — is one line in the controller.

**The entry point is addressed by filename**, `/games/{slug}/play/index.html`,
and a bare `/games/{slug}/play` redirects to it. This is not cosmetic: a
browser resolves a relative asset URL against the *directory* of the page URL,
so serving the entry at `.../play` makes `src="js/main.js"` resolve to
`/games/{slug}/js/main.js` — every asset 404s while the HTML itself loads
fine.

The migration `move_game_bundles_to_protected_storage` moves anything that was
already extracted under the public disk and rewrites `entry_path` to be
relative to its bundle.

### The ZIP is untrusted input

An archive from an admin is still attacker-controlled if that account is ever
compromised, and files under the public disk are reachable over HTTP.
`GameBundleExtractor` therefore validates the whole archive **before writing
anything**, and rejects:

- **Path traversal** — `../`, absolute paths, drive letters, stream wrappers.
  Without this a zip can write outside its folder ("zip slip").
- **Executable types** — `.php`, `.phar`, `.cgi`, `.sh`, `.htaccess` and friends.
  This one matters: a `.php` dropped under `storage/app/public` is *executed*,
  not served — verified against the running server — so this is the difference
  between hosting a game and handing over remote code execution.
- **Zip bombs** — 300 MB unpacked and 5000 entries, checked while planning.
- **Archives with no `index.html`** anywhere.

### Finding the game inside the archive

Real archives are untidy, so the extractor looks for the **shallowest**
`index.html` (or `index.htm`, case-insensitive) at any depth and treats its
folder as the bundle root. That covers build output in `dist/game/`, a game
folder zipped next to a `docs/` sibling, and a capitalised `Index.html`.
Anything outside that folder is dropped. `__MACOSX/` and `.DS_Store` are
skipped.

An upload PHP itself rejected (over `upload_max_filesize`) reports the actual
limit instead of a bare "bundle is required", and every rejected bundle is
logged with its reason.

The guards have negative tests: disabling them makes
`GameBundleTest` fail on exactly the traversal, executable and `.htaccess`
cases.

## Popularity

`games.plays_count` is the popularity figure the app shows. It is incremented
by `POST /api/v1/games/{slug}/play`, which the app calls when somebody presses
Play — not by the file server, so loading a game's assets cannot inflate it,
and hosted and linked games are counted the same way. Unpublished games 404.

## Trailers

A game can carry a trailer video, uploaded on **its own page**
(`/admin/games/{game}/trailer`). Keeping it separate from the details form is
deliberate: videos are large, and a slow upload that fails should not take the
rest of a game's edits with it. The page shows a real progress bar, previews
the picked file before upload, and previews what is already stored.

Trailers live on the protected disk (`storage/app/private/trailers/`) and are
streamed by `TrailerController`, with the same published-or-admin rule as game
bundles.

**Range requests matter here.** `response()->file()` returns a
`BinaryFileResponse`, which the kernel prepares with `Range` support — without
it a player cannot seek, and some clients refuse to start at all. There is a
test asserting a `206` with the exact `Content-Range`.

Validation uses `mimetypes:` (which sniffs the file's contents) rather than
`mimes:` (which trusts the extension), so a renamed file is rejected. The size
cap follows `php.ini`, like the bundle upload.

## Uploaded images are shrunk

Every image upload — game covers, post images, avatars — goes
through `App\Services\ImageStore`, which downscales anything larger than the
app will ever draw it:

| | longest edge |
|---|---|
| Game cover | 1200 |
| Post image | 1600 |
| Avatar | 512 |

A 4032×3024 phone photo of 1.71 MB comes out at 189 KB as a cover and 65 KB
as an avatar. Aspect ratio is kept, the file keeps its own type, transparent
PNGs stay transparent, and a photo carrying EXIF orientation is turned
upright rather than stored sideways.

An image already inside the limit is stored byte for byte — re-encoding
something small only loses detail. And if the image cannot be read at all,
for want of GD or anything else, the original is stored as it arrived: a
heavy cover is a much smaller problem than an admin who cannot save one.

## Cover images

The games form takes a real upload (JPG/PNG/WebP, 4 MB cap) with a live
preview, not a path typed by hand. Three things the code takes care of:

- Replacing a cover deletes the file it replaced, so edits do not leave
  orphans on disk.
- Deleting a game deletes its cover, via a `deleting` hook on the model rather
  than the controller, so it cannot be forgotten by another call site.
- Inertia cannot send files over `PUT`, so the edit form posts with
  `_method: put` and `forceFormData`.

`Game::cover_url` resolves an uploaded path to a URL and returns `null` for the
`assets/...` paths that point at artwork bundled inside the Flutter app.

## Notes

- Adding the required `username` column broke Breeze registration, which never
  set one. `User::uniqueUsername()` derives a free handle; registration uses it.
- Handles are validated as `[a-zA-Z0-9_]`, so `UserFactory` strips the dots
  faker puts in `userName()` — factory data should never be invalid input.
- The seeder mirrors the Flutter app's mock data, so pointing the app at this
  API gives the same screen.

## Tests

```sh
php artisan test
```
