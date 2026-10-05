import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/presence.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Records presence calls; answers login so an [Auth] can hold a session.
class _Server {
  final calls = <String>[];

  http.Client get client => MockClient((request) async {
    if (request.url.path.endsWith('/login')) {
      return http.Response(
        jsonEncode({
          'token': 'test-token',
          'user': {'id': 1, 'name': 'You', 'handle': 'you'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (request.url.path.endsWith('/me/presence')) {
      calls.add(request.method);
      return http.Response('', 204);
    }

    return http.Response('{}', 404);
  });
}

void main() {
  late _Server server;
  late Auth auth;
  late PresenceTracker presence;

  setUp(() {
    server = _Server();
    auth = Auth(client: server.client);
    presence = PresenceTracker(
      auth: auth,
      client: server.client,
      interval: const Duration(seconds: 60),
    );
  });

  // Timer-driven tests dispose inside the body: the pending-timer check runs
  // before tearDown. Disposing twice is harmless.
  tearDown(() => presence.dispose());

  Future<void> signIn() async {
    final error = await auth.signIn(email: 'a@b.c', password: 'password');
    expect(error, isNull);
  }

  test('nobody signed in, nothing is sent', () async {
    presence.start();
    await pumpEventQueue();

    expect(server.calls, isEmpty);
  });

  testWidgets('signing in starts the heartbeat at once, then every interval', (
    tester,
  ) async {
    presence.start();
    await signIn();
    await tester.pump();
    expect(server.calls, ['POST']);

    await tester.pump(const Duration(seconds: 60));
    expect(server.calls, ['POST', 'POST']);
    presence.dispose();
  });

  testWidgets('going to the background says goodbye and stops beating', (
    tester,
  ) async {
    presence.start();
    await signIn();
    await tester.pump();

    presence.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump();
    expect(server.calls, ['POST', 'DELETE']);

    await tester.pump(const Duration(minutes: 5));
    expect(server.calls, ['POST', 'DELETE']);

    presence.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(server.calls, ['POST', 'DELETE', 'POST']);
    presence.dispose();
  });

  testWidgets('a system sheet over the app does not count as leaving', (
    tester,
  ) async {
    presence.start();
    await signIn();
    await tester.pump();

    presence.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 1));

    expect(server.calls, ['POST']);
    presence.dispose();
  });
}
