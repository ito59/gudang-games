# Google Sign-In setup

The code is in place and tested. What is left is the part only you can do:
creating the OAuth clients in Google Cloud and pasting the web client ID into
`backend/.env`. That is the only place — the app asks the server for it at
startup, so there is no rebuild and nothing that can disagree.

Until then the button is hidden in release builds and shown with the reason in
debug builds, and the endpoint answers `503`.

## 1. Create the OAuth clients

You need **two** clients in the **same** Google Cloud project:

| Client | What it does | Where its ID goes |
| --- | --- | --- |
| Android | Tells Google this app is allowed to sign people in | Nowhere — registering it is the whole job |
| Web application | Names the audience Google stamps on the token | `GOOGLE_SERVER_CLIENT_ID` in `backend/.env` |

Creating only the web client makes the chooser fail; creating only the Android
client means no ID token comes back. Both, same project.

### a. Project and consent screen

1. Open [console.cloud.google.com](https://console.cloud.google.com/) and
   create a project (or pick an existing one).
2. Go to **APIs & Services → OAuth consent screen** — newer consoles call this
   **Google Auth Platform**. Configure it before creating any client; the
   client form is blocked until it exists.
   - User type **External**, app name, support email, developer email.
3. While the publishing status is **Testing**, only listed accounts can sign
   in. Add the Google accounts you will test with under **Audience → Test
   users** (up to 100). Anyone not listed gets refused with no useful message.

No API needs enabling. This flow only asks for an ID token; the People API is
only for reading extra profile data, which the app does not do.

### b. Android client

**Credentials → Create credentials → OAuth client ID → Android**

- **Package name**: `id.co.ki89.gudanggames` (the `applicationId` in
  `android/app/build.gradle.kts`)
- **SHA-1**: the fingerprint of the key that signs the build you install.

```sh
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore -storepass android -keypass android
```

Right now `android/app/build.gradle.kts` signs **release with the debug key**
(there is a `TODO` on it), so this one fingerprint covers both `flutter run`
and the release APK. The moment you add a real release keystore, register its
SHA-1 too — a missing release SHA-1 is the usual reason sign-in works in debug
and not in the installed APK, and on Android that failure arrives as
"cancelled" rather than as a configuration error.

If you later ship through Play with Play App Signing, also add the SHA-1 shown
under **Release → Setup → App signing**.

### c. Web application client

**Credentials → Create credentials → OAuth client ID → Web application**

Despite the name this is not for a website. Android asks Google for a token
*aimed at your server*, and this client's ID is what Google puts in the token's
`aud` — which is what the backend checks.

Name it something like `BandarGames API`. No redirect URI or JavaScript origin
is needed. Copy the client ID; it ends in `.apps.googleusercontent.com`.

### d. iOS client — only if you ship an iOS build

Create an iOS client with the bundle ID `id.co.ki89.gudanggames`, put its ID in
`GOOGLE_IOS_CLIENT_ID`, then edit `ios/Runner/Info.plist`:

```xml
<key>GIDClientID</key>
<string>YOUR-IOS-CLIENT-ID.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- The iOS client ID with its parts reversed. -->
      <string>com.googleusercontent.apps.YOUR-IOS-CLIENT-ID</string>
    </array>
  </dict>
</array>
```

An iOS token carries the **iOS** client ID in `aud`, and setting
`GOOGLE_IOS_CLIENT_ID` adds it to the accepted list automatically.

## 2. Put the web client ID in `backend/.env`

```
GOOGLE_SERVER_CLIENT_ID=<web client id>.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=            # only if you ship iOS
```

Then `php artisan config:clear` and restart the server. Check it took:

```sh
curl -s http://192.168.18.131:8000/api/v1/config
# {"google":{"enabled":true,"server_client_id":"...","ios_client_id":null}}
```

That is the whole configuration. The app fetches this at startup, so restarting
it is enough to make the button appear — no rebuild, no `--dart-define`.

The list of audiences the server accepts defaults to these two IDs. That
accept-list is a security boundary, not a convenience: Google will happily sign
a valid ID token for any app, and the audience check is what makes it a sign-in
to *this* one. An empty list disables the endpoint rather than accepting
anything. `GOOGLE_CLIENT_IDS` exists to widen it, and is almost never needed.

### Pinning a build instead

To tie an APK to a specific client regardless of the server it talks to:

```sh
flutter run \
  --dart-define=API_BASE_URL=http://192.168.18.131:8000 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>.apps.googleusercontent.com
```

A build-time value wins over whatever the server reports.

## How it fits together

1. At startup the app reads `GET /api/v1/config` and learns the client ID.
2. It asks Google for an ID token aimed at that client.
3. It posts the token to `POST /api/v1/auth/google`.
4. The backend verifies the signature against Google's published keys, checks
   the issuer, the expiry, and that `aud` is one of ours.
5. It finds the member by `google_id`, else by verified email, else creates one,
   and returns a Sanctum token — the same token the email form returns.

The Google token is never stored and never used as a session token.

## Account linking

Signing in with Google using an address that already has a password account
attaches to that account rather than making a second one — but only when Google
reports the address as verified. Without that rule, anyone able to create a
Google account claiming an address could walk into the account that owns it.

An account created through Google has **no password**. It can only sign in
through Google until someone adds one.

## Known gap

The button uses a placeholder mark, not Google's own logo. Google's branding
terms require their supplied asset, used unmodified — drop the official PNG or
SVG into `assets/` and swap out `_GoogleMark` in
`lib/widgets/google_sign_in_button.dart` before shipping to a store.

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| Chooser opens, then "cancelled" straight away | SHA-1 not registered, or the account is not a test user while the consent screen is in Testing |
| `[10] Developer console is not set up correctly` | SHA-1, package name, or client ID wrong. Google's own sheet never appears |
| `[16] Account reauth failed` | Not an app problem: Google's sheet appeared, then Play services could not re-verify the device account. Complete any pending verification on that Google account, or remove and re-add it in Android Settings |
| "Google did not return an ID token" | `GOOGLE_SERVER_CLIENT_ID` missing from the build |
| Button still missing after configuring | App not restarted, or it cannot reach `API_BASE_URL`. Check `curl .../api/v1/config` from the phone's network |
| `503 Google sign-in is not enabled` | `GOOGLE_SERVER_CLIENT_ID` empty, or config not cleared |
| `422 That Google sign-in could not be verified` | `aud` is not accepted — usually the Android client ID was pasted instead of the web one. `storage/logs/laravel.log` records the `aud` it saw |
| Works in debug, not in release | Release SHA-1 (or the Play App Signing SHA-1) not registered |
