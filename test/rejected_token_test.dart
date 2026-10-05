import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/services/chat_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';

import 'support/fake_chat.dart';
import 'support/preferences.dart';

Future<Auth> _signedIn(FakeChatServer server) async {
  resetPreferences();
  final auth = Auth(client: server.client);
  expect(await auth.signIn(email: 'a@b.c', password: 'x'), isNull);
  expect(auth.isSignedIn, isTrue);
  return auth;
}

void main() {
  test('a refused token ends the session', () async {
    final server = FakeChatServer()..seedThread(memberId: 2, name: 'Dita');
    final auth = await _signedIn(server);
    final chat = ChatRepository(auth: auth, client: server.client);

    // The server no longer knows this token — revoked, wiped with the
    // database, or issued by a backend this build no longer points at.
    server.rejectTokens = true;
    await chat.conversations();

    expect(auth.isSignedIn, isFalse);
  });

  test('the member is asked to sign in rather than left stuck', () async {
    final server = FakeChatServer();
    final auth = await _signedIn(server);

    var notified = 0;
    auth.addListener(() => notified++);

    server.rejectTokens = true;
    await ChatRepository(auth: auth, client: server.client).openWith(2);

    // Screens read `isSignedIn`; without the notification they keep showing
    // a signed-in member whose every action fails.
    expect(notified, greaterThan(0));
    expect(auth.isSignedIn, isFalse);
  });

  test('the dropped token does not come back on the next run', () async {
    final server = FakeChatServer();
    final auth = await _signedIn(server);

    server.rejectTokens = true;
    await ChatRepository(auth: auth, client: server.client).openWith(2);
    // Let the write to storage settle.
    await Future<void>.delayed(Duration.zero);

    final next = Auth(client: server.client);
    await next.load();

    expect(next.isSignedIn, isFalse);
  });

  test('an ordinary failure leaves the session alone', () async {
    final server = FakeChatServer()..failSends = true;
    final auth = await _signedIn(server);
    final chat = ChatRepository(auth: auth, client: server.client);
    final thread = await chat.openWith(2);

    final sent = await chat.send(thread!.id, 'Halo');

    expect(sent.message, isNull, reason: 'nothing was stored');
    expect(sent.error, isNotNull, reason: 'the sender is told');

    // A 500 says the server had a problem, not that the member is a
    // stranger. Signing them out over it would be wrong.
    expect(auth.isSignedIn, isTrue);
  });

  test('the chat controller clears what it was holding', () async {
    final server = FakeChatServer()..seedThread(memberId: 2, name: 'Dita');
    final auth = await _signedIn(server);
    final controller = ChatController(
      repository: ChatRepository(auth: auth, client: server.client),
      realtime: FakeRealtime(),
      auth: auth,
    );

    await controller.load();
    expect(controller.conversations, hasLength(1));

    server.rejectTokens = true;
    await controller.load();

    // Signed out is signed out: somebody else's threads must not stay on
    // screen behind a sign-in prompt.
    expect(auth.isSignedIn, isFalse);
    expect(controller.conversations, isEmpty);
  });
}
