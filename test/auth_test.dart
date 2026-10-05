import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bandar_games/state/auth_scope.dart';

import 'support/preferences.dart';

/// Both sign-in routes share one response handler, so the email form's
/// behaviour is covered here rather than assumed.
MockClient _server(int status, Map<String, Object?> body) {
  return MockClient(
    (_) async => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    ),
  );
}

void main() {
  setUp(resetPreferences);

  test('a good sign in keeps the token and the member', () async {
    final auth = Auth(
      client: _server(200, {
        'token': 'sanctum-token',
        'user': {
          'data': {'id': 2, 'name': 'Dita Prameswari', 'handle': 'ditaprams'},
        },
      }),
    );

    expect(await auth.signIn(email: 'a@b.c', password: 'password'), isNull);
    expect(auth.isSignedIn, isTrue);
    // The resource is wrapped in `data`; the flat shape has to work too.
    expect(auth.user?.handle, 'ditaprams');
  });

  test('a rejected password surfaces the field error verbatim', () async {
    final auth = Auth(
      client: _server(422, {
        'message': 'The given data was invalid.',
        'errors': {
          'email': ['These credentials do not match our records.'],
        },
      }),
    );

    expect(
      await auth.signIn(email: 'a@b.c', password: 'wrong'),
      'These credentials do not match our records.',
    );
    expect(auth.isSignedIn, isFalse);
  });

  test('a 200 without a token is not treated as a session', () async {
    final auth = Auth(client: _server(200, {'user': {'handle': 'x'}}));

    expect(await auth.signIn(email: 'a@b.c', password: 'p'), isNotNull);
    expect(auth.isSignedIn, isFalse);
  });

  test('a non-JSON response does not crash the sign in', () async {
    final auth = Auth(
      client: MockClient((_) async => http.Response('<html>502</html>', 502)),
    );

    expect(await auth.signIn(email: 'a@b.c', password: 'p'), isNotNull);
    expect(auth.isSignedIn, isFalse);
  });

  test('signing out clears the stored session', () async {
    final auth = Auth(
      client: _server(200, {
        'token': 'sanctum-token',
        'user': {'id': 1, 'name': 'You', 'handle': 'you'},
      }),
    );
    await auth.signIn(email: 'a@b.c', password: 'password');

    await auth.signOut();

    final restarted = Auth();
    await restarted.load();
    expect(restarted.isSignedIn, isFalse);
  });
}
