import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/screens/chat_screen.dart';
import 'package:bandar_games/services/chat_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_chat.dart';
import 'support/preferences.dart';

/// The filter itself lives on the server — the app cannot be trusted to run
/// it, and these tests do not pretend otherwise. What is checked here is the
/// half the app owns: that a refusal reaches the person who wrote the
/// message, in the server's own words, and that nothing is left looking sent.
late Auth auth;

Future<ChatController> _controller(FakeChatServer server) async {
  resetPreferences();
  auth = Auth(client: server.client);
  await auth.signIn(email: 'a@b.c', password: 'x');

  return ChatController(
    repository: ChatRepository(auth: auth, client: server.client),
    realtime: FakeRealtime(),
    auth: auth,
  );
}

Future<void> _pump(WidgetTester tester, ChatController chat, String id) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ChatScope(
      notifier: chat,
      child: AuthScope(
        notifier: auth,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: ChatScreen(conversationId: id),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const refusal = 'That message contains a word that is not allowed here.';

  testWidgets('a refused message says why, in the server\'s words', (
    tester,
  ) async {
    final server = FakeChatServer()..refuseSendsWith = refusal;
    final chat = await _controller(server);
    final id = server.seedThread(memberId: 2, name: 'Dita');
    await chat.load();

    await _pump(tester, chat, id);

    await tester.enterText(find.byType(TextField), 'something rude');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    // The reason, not a generic failure — otherwise they simply send it again.
    expect(find.text(refusal), findsOneWidget);
  });

  testWidgets('a refused message is not left looking sent', (tester) async {
    final server = FakeChatServer()..refuseSendsWith = refusal;
    final chat = await _controller(server);
    final id = server.seedThread(memberId: 2, name: 'Dita');
    await chat.load();

    await _pump(tester, chat, id);

    await tester.enterText(find.byType(TextField), 'something rude');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    // Shown optimistically, then taken back: the thread must not keep a
    // message the server never stored.
    expect(find.text('something rude'), findsNothing);
    expect(chat.byId(id)!.messages, isEmpty);
    expect(server.messages[id], isEmpty);
  });

  testWidgets('an ordinary failure still says something', (tester) async {
    final server = FakeChatServer()..failSends = true;
    final chat = await _controller(server);
    final id = server.seedThread(memberId: 2, name: 'Dita');
    await chat.load();

    await _pump(tester, chat, id);

    await tester.enterText(find.byType(TextField), 'hello there');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    // A 500 carries nothing worth reading, so the app supplies the words.
    expect(find.text('That message did not send.'), findsOneWidget);
  });

  testWidgets('a clean message goes through untouched', (tester) async {
    final server = FakeChatServer();
    final chat = await _controller(server);
    final id = server.seedThread(memberId: 2, name: 'Dita');
    await chat.load();

    await _pump(tester, chat, id);

    await tester.enterText(find.byType(TextField), 'good game');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.text('good game'), findsOneWidget);
    expect(server.messages[id], hasLength(1));
  });
}
