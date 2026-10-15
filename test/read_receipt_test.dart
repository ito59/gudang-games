import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/models/chat_message.dart';
import 'package:bandar_games/screens/chat_screen.dart';
import 'package:bandar_games/services/chat_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';
import 'package:bandar_games/theme/app_icons.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_chat.dart';
import 'support/preferences.dart';

late Auth auth;

Future<ChatController> _controller(
  FakeChatServer server,
  FakeRealtime realtime,
) async {
  resetPreferences();
  auth = Auth(client: server.client);
  expect(await auth.signIn(email: 'a@b.c', password: 'x'), isNull);

  return ChatController(
    repository: ChatRepository(auth: auth, client: server.client),
    realtime: realtime,
    auth: auth,
  );
}

MessageStatus _statusOf(ChatController chat, String thread, String body) =>
    chat.byId(thread)!.messages.firstWhere((m) => m.text == body).status;

void main() {
  group('the tick', () {
    test('a sent message is not read until somebody says it was', () async {
      final server = FakeChatServer();
      final chat = await _controller(server, FakeRealtime());
      final thread = await chat.openWith(2);

      await chat.send(thread!.id, 'Halo');

      // The old default made every message read the moment it existed.
      expect(_statusOf(chat, thread.id, 'Halo'), MessageStatus.sent);
    });

    test('reopening a thread does not invent a read receipt', () async {
      final server = FakeChatServer();
      final id = server.seedThread(memberId: 2, name: 'Dita');
      server.seedMessage(id, 'Mine', authorId: 1);

      final chat = await _controller(server, FakeRealtime());
      await chat.load();
      await chat.loadThread(id);

      expect(_statusOf(chat, id, 'Mine'), MessageStatus.sent);
    });

    test('the pointer from the server marks what it covers', () async {
      final server = FakeChatServer();
      final id = server.seedThread(memberId: 2, name: 'Dita');
      server.seedMessage(id, 'Seen', authorId: 1);
      server.seedMessage(id, 'Sent after', authorId: 1);
      // They read as far as the first, then looked away.
      server.conversations.first['their_last_read_id'] = 1;

      final chat = await _controller(server, FakeRealtime());
      await chat.load();
      await chat.loadThread(id);

      expect(_statusOf(chat, id, 'Seen'), MessageStatus.read);
      expect(_statusOf(chat, id, 'Sent after'), MessageStatus.sent);
    });

    test('a receipt arriving live turns the ticks blue', () async {
      final server = FakeChatServer();
      final id = server.seedThread(memberId: 2, name: 'Dita');
      server.seedMessage(id, 'Mine', authorId: 1);
      final realtime = FakeRealtime();

      final chat = await _controller(server, realtime);
      await chat.load();
      await chat.loadThread(id);
      expect(_statusOf(chat, id, 'Mine'), MessageStatus.sent);

      realtime.markRead(id, readerId: 2, upTo: 1);
      await Future<void>.delayed(Duration.zero);

      // Without closing and reopening the thread.
      expect(_statusOf(chat, id, 'Mine'), MessageStatus.read);
    });

    test('our own read, echoed back, changes nothing', () async {
      final server = FakeChatServer();
      final id = server.seedThread(memberId: 2, name: 'Dita');
      server.seedMessage(id, 'Mine', authorId: 1);
      final realtime = FakeRealtime();

      final chat = await _controller(server, realtime);
      await chat.load();
      await chat.loadThread(id);

      // Reading it ourselves says nothing about the other seat.
      realtime.markRead(id, readerId: 1, upTo: 1);
      await Future<void>.delayed(Duration.zero);

      expect(_statusOf(chat, id, 'Mine'), MessageStatus.sent);
    });
  });

  testWidgets('the thread on screen updates without being reopened', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final server = FakeChatServer();
    final id = server.seedThread(memberId: 2, name: 'Dita');
    server.seedMessage(id, 'Sudah dibaca?', authorId: 1);
    final realtime = FakeRealtime();

    final chat = await _controller(server, realtime);
    await chat.load();

    await tester.pumpWidget(
      ChatScope(
        notifier: chat,
        child: AuthScope(
          notifier: auth,
          child: MaterialApp(
            theme: AppTheme.light,
            home: ChatScreen(conversationId: id),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // One tick: delivered. Two: they have read it.
    expect(find.byIcon(AppIcons.check), findsOneWidget);
    expect(find.byIcon(AppIcons.doneAll), findsNothing);

    realtime.markRead(id, readerId: 2, upTo: 1);
    await tester.pumpAndSettle();

    // The thread was never closed and reopened.
    expect(find.byIcon(AppIcons.doneAll), findsOneWidget);
    expect(find.byIcon(AppIcons.check), findsNothing);
  });
}
