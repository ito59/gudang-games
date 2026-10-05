import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bandar_games/screens/sign_in_screen.dart';
import 'package:bandar_games/services/google_authenticator.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_google.dart';
import 'support/preferences.dart';

/// The backend's `/auth/google` route, reduced to what the app relies on.
MockClient _backend({
  int status = 200,
  Map<String, Object?>? body,
  Map<String, Object?>? config,
  List<Map<String, Object?>>? seen,
}) {
  return MockClient((request) async {
    seen?.add({
      'path': request.url.path,
      if (request.body.isNotEmpty) ...jsonDecode(request.body) as Map,
    });

    if (request.url.path.endsWith('/config')) {
      return http.Response(
        jsonEncode({
          'google': config ?? {'enabled': false, 'server_client_id': null},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    return http.Response(
      jsonEncode(
        body ??
            {
              'token': 'sanctum-token',
              'user': {'id': 7, 'name': 'New Comer', 'handle': 'newcomer'},
              'created': true,
            },
      ),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
}

Future<void> _pumpSignIn(
  WidgetTester tester,
  Auth auth, {
  bool showUnconfiguredGoogle = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    AuthScope(
      notifier: auth,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: SignInScreen(showUnconfiguredGoogle: showUnconfiguredGoogle),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(resetPreferences);
  _precedenceTests();

  group('Auth.signInWithGoogle', () {
    test('exchanges the Google token for one of ours', () async {
      final seen = <Map<String, Object?>>[];
      final auth = Auth(
        client: _backend(seen: seen),
        google: FakeGoogleAuthenticator(idToken: 'from-google'),
      );

      expect(await auth.signInWithGoogle(), isNull);
      expect(auth.isSignedIn, isTrue);
      expect(auth.user?.handle, 'newcomer');
      expect(auth.token, 'sanctum-token');

      // The Google token goes to the backend to be verified, and never
      // stands in for our own session token.
      expect(seen.single['path'], '/api/v1/auth/google');
      expect(seen.single['id_token'], 'from-google');
      expect(auth.token, isNot('from-google'));
    });

    test('the session survives a restart', () async {
      final auth = Auth(client: _backend(), google: FakeGoogleAuthenticator());
      await auth.signInWithGoogle();

      final restarted = Auth();
      await restarted.load();

      expect(restarted.isSignedIn, isTrue);
      expect(restarted.user?.handle, 'newcomer');
    });

    test('a dismissed chooser is reported, not swallowed', () async {
      final auth = Auth(
        client: _backend(),
        google: FakeGoogleAuthenticator(
          cancels: true,
          cancelDetail: '[28444] Developer console is not set up correctly.',
        ),
      );

      // Android reports a misconfigured app as a cancel, so silence here is
      // what makes that failure impossible to place.
      expect(await auth.signInWithGoogle(), isNotNull);
      expect(
        auth.lastGoogleDetail,
        '[28444] Developer console is not set up correctly.',
      );
      expect(auth.isSignedIn, isFalse);
    });

    test('a failed chooser reports its own message', () async {
      final auth = Auth(
        client: _backend(),
        google: FakeGoogleAuthenticator(
          failure: 'Google sign-in is not configured for this app build.',
        ),
      );

      expect(
        await auth.signInWithGoogle(),
        'Google sign-in is not configured for this app build.',
      );
      expect(auth.isSignedIn, isFalse);
    });

    test('a refusal from our backend is surfaced verbatim', () async {
      final auth = Auth(
        client: _backend(
          status: 422,
          body: {
            'message': 'x',
            'errors': {
              'id_token': ['This account is suspended.'],
            },
          },
        ),
        google: FakeGoogleAuthenticator(),
      );

      expect(await auth.signInWithGoogle(), 'This account is suspended.');
      expect(auth.isSignedIn, isFalse);
    });

    test('a server without Google enabled says so', () async {
      final auth = Auth(
        client: _backend(
          status: 503,
          body: {'message': 'Google sign-in is not enabled on this server.'},
        ),
        google: FakeGoogleAuthenticator(),
      );

      expect(
        await auth.signInWithGoogle(),
        'Google sign-in is not enabled on this server.',
      );
    });

    test('with no client ID no chooser is put in front of anyone', () async {
      final google = FakeGoogleAuthenticator(configured: false);
      final auth = Auth(client: _backend(), google: google);

      expect(await auth.signInWithGoogle(), isNotNull);
      expect(google.chooserOpened, 0);
      expect(auth.supportsGoogle, isFalse);
      expect(auth.isSignedIn, isFalse);
    });

    test('the client ID comes from the backend', () async {
      final google = FakeGoogleAuthenticator(configured: false);
      final auth = Auth(
        client: _backend(
          config: {
            'enabled': true,
            'server_client_id': 'web-client.apps.googleusercontent.com',
            'ios_client_id': null,
          },
        ),
        google: google,
      );

      expect(auth.supportsGoogle, isFalse);
      await auth.load();

      // Configuring the server is enough; no rebuild with a --dart-define.
      expect(auth.supportsGoogle, isTrue);
      expect(
        google.adoptedServerClientId,
        'web-client.apps.googleusercontent.com',
      );
    });

    test('a server with Google turned off leaves it unconfigured', () async {
      final google = FakeGoogleAuthenticator(configured: false);
      final auth = Auth(
        client: _backend(
          // A client ID is present but sign-in is switched off: the flag is
          // the only thing that can stop the button appearing.
          config: {
            'enabled': false,
            'server_client_id': 'web-client.apps.googleusercontent.com',
          },
        ),
        google: google,
      );

      await auth.load();

      expect(auth.supportsGoogle, isFalse);
    });

    test(
      'an unreachable server leaves the button hidden, not broken',
      () async {
        final google = FakeGoogleAuthenticator(configured: false);
        final auth = Auth(
          client: MockClient((_) async => throw const SocketException('down')),
          google: google,
        );

        await auth.load();

        expect(auth.supportsGoogle, isFalse);
        expect(auth.isSignedIn, isFalse);
      },
    );

    test('a config call lost at launch is asked again on the tap', () async {
      var online = false;
      final google = FakeGoogleAuthenticator(configured: false);
      final auth = Auth(
        // Down at launch — a VPN in the way — and back by the time the
        // member taps the button.
        client: MockClient((request) async {
          if (!online) throw const SocketException('down');
          if (request.url.path.endsWith('/config')) {
            return http.Response(
              jsonEncode({
                'google': {
                  'enabled': true,
                  'server_client_id': 'web-client.apps.googleusercontent.com',
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'token': 'sanctum-token',
              'user': {'id': 7, 'name': 'New Comer', 'handle': 'newcomer'},
            }),
            200,
          );
        }),
        google: google,
      );

      await auth.load();
      expect(auth.supportsGoogle, isFalse);

      online = true;
      expect(await auth.signInWithGoogle(), isNull);
      expect(
        google.adoptedServerClientId,
        'web-client.apps.googleusercontent.com',
      );
      expect(auth.isSignedIn, isTrue);
    });

    test('signing out also signs out of Google', () async {
      final google = FakeGoogleAuthenticator();
      final auth = Auth(client: _backend(), google: google);
      await auth.signInWithGoogle();

      await auth.signOut();

      // Otherwise the next tap silently reuses the same account with no
      // chooser, which reads as the sign-out having failed.
      expect(google.signOutCalls, 1);
      expect(auth.isSignedIn, isFalse);
    });
  });

  group('SignInScreen', () {
    testWidgets('offers Google and closes on success', (tester) async {
      final auth = Auth(client: _backend(), google: FakeGoogleAuthenticator());
      await _pumpSignIn(tester, auth);

      expect(find.text('Continue with Google'), findsOneWidget);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(auth.isSignedIn, isTrue);
    });

    testWidgets('a release build hides an unconfigured button', (tester) async {
      await _pumpSignIn(
        tester,
        Auth(
          client: _backend(),
          google: FakeGoogleAuthenticator(configured: false),
        ),
        showUnconfiguredGoogle: false,
      );

      // Better absent than present and guaranteed to fail.
      expect(find.text('Continue with Google'), findsNothing);
      expect(find.text('Sign in'), findsWidgets);
    });

    testWidgets('a debug build shows it with the reason instead', (
      tester,
    ) async {
      await _pumpSignIn(
        tester,
        Auth(
          client: _backend(),
          google: FakeGoogleAuthenticator(configured: false),
        ),
        showUnconfiguredGoogle: true,
      );

      // Missing UI with no explanation is the harder thing to diagnose.
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.textContaining('GOOGLE_SERVER_CLIENT_ID'), findsOneWidget);
    });

    testWidgets('the hint is gone once a client ID is known', (tester) async {
      await _pumpSignIn(
        tester,
        Auth(client: _backend(), google: FakeGoogleAuthenticator()),
        showUnconfiguredGoogle: true,
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.textContaining('GOOGLE_SERVER_CLIENT_ID'), findsNothing);
    });

    testWidgets('shows the reason a Google sign-in failed', (tester) async {
      await _pumpSignIn(
        tester,
        Auth(
          client: _backend(),
          google: FakeGoogleAuthenticator(failure: 'Google sign-in failed.'),
        ),
      );

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.text('Google sign-in failed.'), findsOneWidget);
    });

    testWidgets('a dismissed chooser leaves the reason on screen', (
      tester,
    ) async {
      final auth = Auth(
        client: _backend(),
        google: FakeGoogleAuthenticator(
          cancels: true,
          cancelDetail: '[28444] Developer console is not set up correctly.',
        ),
      );
      await _pumpSignIn(tester, auth);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(auth.isSignedIn, isFalse);

      // Returning to the form with nothing said is the bug this replaces.
      expect(find.textContaining('closed before it finished'), findsOneWidget);
      expect(find.textContaining('[28444]'), findsOneWidget);
    });

    testWidgets('the platform detail is shown under a failure too', (
      tester,
    ) async {
      await _pumpSignIn(
        tester,
        Auth(
          client: _backend(),
          google: FakeGoogleAuthenticator(failure: 'Google sign-in failed.'),
        ),
      );

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.text('Google sign-in failed.'), findsOneWidget);
    });
  });
}

/// The real authenticator's own rules, with the plugin left out of it.
void _precedenceTests() {
  group('GoogleSignInAuthenticator', () {
    test('a build-time client ID wins over the server', () {
      final authenticator = GoogleSignInAuthenticator(
        buildServerClientId: 'pinned.apps.googleusercontent.com',
        buildIosClientId: '',
      );

      expect(authenticator.isConfigured, isTrue);

      authenticator.adopt(
        serverClientId: 'from-server.apps.googleusercontent.com',
      );

      // A pinned build must not be repointed by whatever server it talks to.
      expect(
        authenticator.debugServerClientId,
        'pinned.apps.googleusercontent.com',
      );
    });

    test('without a build-time ID the server supplies one', () {
      final authenticator = GoogleSignInAuthenticator(
        buildServerClientId: '',
        buildIosClientId: '',
      );

      expect(authenticator.isConfigured, isFalse);

      authenticator.adopt(
        serverClientId: 'from-server.apps.googleusercontent.com',
      );

      expect(authenticator.isConfigured, isTrue);
      expect(
        authenticator.debugServerClientId,
        'from-server.apps.googleusercontent.com',
      );
    });

    test('an iOS-only client ID is enough to be configured', () {
      final authenticator = GoogleSignInAuthenticator(
        buildServerClientId: '',
        buildIosClientId: '',
      )..adopt(iosClientId: 'ios.apps.googleusercontent.com');

      expect(authenticator.isConfigured, isTrue);
    });
  });
}
