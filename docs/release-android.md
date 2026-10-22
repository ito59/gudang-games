# Releasing to Play Store

## The upload key

One key signs every upload for the life of the app. It lives outside the repo at
`~/keystores/bandar-games-upload.jks`, described to Gradle by
`android/key.properties` (alias `upload`, RSA 4096, valid to 2054). Both files
are gitignored.

**Back up the `.jks` and its password somewhere that survives this laptop.**
Losing it does not end the app — Google can reset an upload key on request —
but it costs days of support round-trips, so treat it as the one irreplaceable
artefact here.

Fingerprint of the upload certificate:

```
SHA-1:   D0:71:1B:2F:A2:51:59:97:56:D2:D2:75:02:C1:94:20:EF:AA:3F:03
SHA-256: 84:9D:0D:73:68:FC:DD:F0:AE:4C:DA:CB:B4:BD:51:03:58:DA:3D:39:47:86:3B:40:27:F8:E3:3C:0A:8B:ED:7B
```

On a fresh checkout without `key.properties`, release builds fall back to the
debug key. That is deliberate — `flutter run --release` keeps working, and Play
refuses the artefact loudly rather than you shipping something unsigned.

## Building

```sh
flutter build appbundle --release
```

The bundle lands at `build/app/outputs/bundle/release/app-release.aab`.

Bump `version:` in `pubspec.yaml` before every upload — the part after `+` is
the `versionCode`, and Play rejects a build whose `versionCode` it has already
seen. `1.0.0+1` → `1.0.1+2`, and so on.

## Uploading to internal testing

1. Play Console → **Testing → Internal testing → Create new release**.
2. Keep **Play App Signing** on (the default). Google holds the *app signing*
   key and re-signs what you upload; your upload key only proves the upload
   came from you.
3. Upload the `.aab`, write release notes, **Review release → Start rollout**.
4. Under **Testers**, add an email list. Internal testing takes up to 100
   testers and goes live in minutes rather than the days review takes.
5. Share the opt-in link. Testers must accept it with the same Google account
   they use on the device.

## After the first upload: Google Sign-In

Play App Signing means the certificate on the installed app is **Google's**,
not the upload key above. Sign-in will fail on Play-installed builds until that
fingerprint is registered:

1. Play Console → **Protected with Play → Play Store distribution → Go to
   Play app signing**. (The old **Setup → App signing** path is gone as of the
   2026 console; if the menu is hard to find, open the app and replace the tail
   of the URL with `/keymanagement`.)
2. The page shows two blocks. Copy the SHA-1 from **App signing key
   certificate** — Google's key, the one on every Play-installed build.
   Nothing appears here until the first bundle is uploaded, because the key
   does not exist before then.
3. Google Cloud (the same project as the web client) → **Credentials →
   Create credentials → OAuth client ID → Android**, package
   `id.co.ki89.gudanggames`, that SHA-1. An Android client holds exactly one
   fingerprint, so this is a **new** client beside the existing one, not an
   edit of it. Nothing to paste anywhere afterwards; the change can take a few
   minutes to reach devices.

Do the same with the **Upload key certificate** SHA-1 — same page, second
block — so a release APK built and installed locally signs in as well. See
[google-sign-in.md](google-sign-in.md) for the rest of the OAuth setup.

The three Android clients this app needs, all package `id.co.ki89.gudanggames`:

| Client | SHA-1 | Signs |
| --- | --- | --- |
| Play | _from Play Console after the first upload_ | Every Play-installed build |
| Release | `D0:71:1B:2F:A2:51:59:97:56:D2:D2:75:02:C1:94:20:EF:AA:3F:03` | Release builds installed by hand |
| Debug | the debug keystore's, per machine | `flutter run` |

The two blocks on the Play page are easy to swap. If Play-installed builds
still fail with `[16] Account reauth failed`, read the certificate off the
installed app rather than the console — with the phone on adb:

```sh
adb pull "$(adb shell pm path id.co.ki89.gudanggames | grep base.apk | cut -d: -f2 | tr -d '\r')" installed.apk
$ANDROID_HOME/build-tools/<version>/apksigner verify --print-certs installed.apk
```

A `CN=Android, O=Google Inc.` signer is Play's key; that SHA-1 is the one to
register. (`keytool -printcert -jarfile` prints nothing here — Play ships
v2/v3-signed APKs only.)
