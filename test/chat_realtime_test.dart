import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/models/chat_message.dart';
import 'package:bandar_games/screens/chat_screen.dart';
import 'package:bandar_games/screens/messages_screen.dart';
import 'package:bandar_games/services/chat_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';
import 'package:bandar_games/theme/app_icons.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_chat.dart';
import 'support/preferences.dart';

/// The session [_controller] last built, for the widgets that need one.
late Auth auth;

/// A signed-in controller wired to [server] and [realtime].
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

Future<void> _pump(WidgetTester tester, ChatController chat, Widget screen) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ChatScope(
      notifier: chat,
      // The chat screens send a signed-out visitor to sign in, so they need
      // a session to be left alone.
      child: AuthScope(
        notifier: auth,
        child: MaterialApp(theme: AppTheme.dark, home: screen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the controller', () {
    test('threads come from the server, not from seed data', () async {
      final server = FakeChatServer()..seedThread(memberId: 2, name: 'Dita');
      final realtime = FakeRealtime();
      final chat = await _controller(server, realtime);

      await chat.load();

      expect(chat.conversations, hasLength(1));
      expect(chat.conversations.first.name, 'Dita');
      expect(server.calls, contains('GET /api/v1/conversations'));
    });

    test('every loaded thread is listened to', () async {
      final server = FakeChatServer()
        ..seedThread(memberId: 2, name: 'Dita')
        ..seedThread(memberId: 3, name: 'Bagas');
      final realtime = FakeRealtime();
      final chat = await _controller(server, realtime);

      await chat.load();

      expect(realtime.subscribed, [
        'private-conversation.1',
        'private-conversation.2',
      ]);
    });

    test('messaging somebody opens their thread once', () async {
      final server = FakeChatServer();
      final realtime = FakeRealtime();
      final chat = await _controller(server, realtime);

      final first = await chat.openWith(7);
      final again = await chat.openWith(7);

      expect(first, isNotNull);
      expect(again!.id, first!.id);
      expect(chat.conversations, hasLength(1));
      // Subscribing twice would double every arriving message.
      expect(realtime.subscribed, ['private-conversation.1']);
    });

    test('a sent message shows at once and keeps the server copy', () async {
      final server = FakeChatServer();
      final realtime = FakeRealtime();
      final chat = await _controller(server, realtime);
      final thread = await chat.openWith(2);

      expect(await chat.send(thread!.id, 'Halo'), isNull);

      final messages = chat.byId(thread.id)!.messages;
      expect(messages, hasLength(1));
      expect(messages.single.text, 'Halo');
      expect(messages.single.isMine, isTrue);
      expect(messages.single.status, MessageStatus.sent);
      // Not a pending placeholder: the id is the row the server stored.
      expect(messages.single.id, isNot(startsWith('pending-')));
    });

    test('the send declares its socket so it is not echoed back', () async {
      final server = FakeChatServer();
      final realtime = FakeRealtime();
      final chat = await _controller(server, realtime);
      final thread = await chat.openWith(2);

      await chat.send(thread!.id, 'Halo');

      expect(server.sentSocketIds, ['fake.socket']);
    });

    test('a message the server refuses is rolled back', () async {
      final server = FakeChatServer()..failSends = true;
      final realtime = FakeRealtime();
      final chat = await _controller(server, realtime);
      final thread = await chat.openWith(2);

      final error = await chat.send(thread!.id, 'Halo');

      expect(error, 'That message did not send.');
      // It must not be left sitting there looking sent.
      expect(chat.byId(thread.id)!.messages, isEmpty);
    });

    test('an empty message is not sent at all', () async {
      final server = FakeChatServer();
      final chat = await _controller(server, FakeRealtime());
      final thread = await chat.openWith(2);

      expect(await chat.send(thread!.id, '   '), isNull);
      expect(server.calls, isNot(contains('POST /api/v1/conversations/1/messages')));
    });

    test('a message arriving on the socket lands in the thread', () async {
      final server = FakeChatServer()..seedThread(memberId: 2, name: 'Dita');
      final realtime = FakeRealtime();
      final chat = await _controller(server, realtime);
      await chat.load();

      realtime.deliver('1', {
        'id': '99',
        'body': 'Live from the socket',
        'author': {'id': 2, 'name': 'Dita'},
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      await Future<void>.delayed(Duration.zero);

      final thread = chat.byId('1')!;
      expect(thread.messages.single.text, 'Live from the socket');
      expect(thread.messages.single.isMine, isFalse);
      expect(thread.unread, 1);
      expect(chat.totalUnread, 1);
    });

    test('the same message twice is only kept once', () async {
      final server = FakeChatServer()..seedThread(memberId: 2, name: 'Dita');
      final realtime = FakeRealtime();
      final chat = await _controller(server, realtime);
      await chat.load();

      final payload = {
        'id': '99',
        'body': 'Once',
        'author': {'id': 2, 'name': 'Dita'},
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      // A reconnect can replay what was already delivered.
      realtime.deliver('1', payload);
      realtime.deliver('1', payload);
      await Future<void>.delayed(Duration.zero);

      expect(chat.byId('1')!.messages, hasLength(1));
    });

    test('opening a thread reads its history and clears the badge', () async {
      final server = FakeChatServer();
      final id = server.seedThread(memberId: 2, name: 'Dita', unread: 2);
      server.seedMessage(id, 'Theirs', authorId: 2);
      server.seedMessage(id, 'Mine', authorId: 1);

      final chat = await _controller(server, FakeRealtime());
      await chat.load();
      expect(chat.totalUnread, 2);

      await chat.loadThread(id);

      final messages = chat.byId(id)!.messages;
      expect(messages.map((m) => m.text), ['Theirs', 'Mine']);
      // Whose is whose is worked out from the author, not trusted from the API.
      expect(messages.first.isMine, isFalse);
      expect(messages.last.isMine, isTrue);
      expect(chat.totalUnread, 0);
      expect(server.calls, contains('POST /api/v1/conversations/$id/read'));
    });

    test('signing out drops somebody else\'s messages', () async {
      resetPreferences();
      final server = FakeChatServer()..seedThread(memberId: 2, name: 'Dita');
      final auth = Auth(client: server.client);
      await auth.signIn(email: 'a@b.c', password: 'x');

      final chat = ChatController(
        repository: ChatRepository(auth: auth, client: server.client),
        realtime: FakeRealtime(),
        auth: auth,
      );
      await chat.load();
      expect(chat.conversations, hasLength(1));

      await auth.signOut();

      expect(chat.conversations, isEmpty);
    });
  });

  group('the screens', () {
    testWidgets('the list shows threads from the server', (tester) async {
      final server = FakeChatServer();
      final id = server.seedThread(memberId: 2, name: 'Dita Prameswari');
      server.seedMessage(id, 'See you tonight', authorId: 2);

      final chat = await _controller(server, FakeRealtime());
      await _pump(tester, chat, const MessagesScreen());

      expect(find.text('Dita Prameswari'), findsOneWidget);
      expect(find.text('See you tonight'), findsOneWidget);
    });

    testWidgets('an empty list says so instead of sitting blank', (
      tester,
    ) async {
      final chat = await _controller(FakeChatServer(), FakeRealtime());
      await _pump(tester, chat, const MessagesScreen());

      expect(
        find.textContaining('No messages yet'),
        findsOneWidget,
      );
    });

    testWidgets('opening a thread shows its history', (tester) async {
      final server = FakeChatServer();
      final id = server.seedThread(memberId: 2, name: 'Dita');
      server.seedMessage(id, 'Are you on later?', authorId: 2);

      final chat = await _controller(server, FakeRealtime());
      await chat.load();
      await _pump(tester, chat, ChatScreen(conversationId: id));

      expect(find.text('Are you on later?'), findsOneWidget);
    });

    testWidgets('a message typed in the thread reaches the server', (
      tester,
    ) async {
      final server = FakeChatServer();
      final id = server.seedThread(memberId: 2, name: 'Dita');

      final chat = await _controller(server, FakeRealtime());
      await chat.load();
      await _pump(tester, chat, ChatScreen(conversationId: id));

      await tester.enterText(find.byType(TextField), 'On my way');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(AppIcons.send));
      await tester.pumpAndSettle();

      expect(server.calls, contains('POST /api/v1/conversations/$id/messages'));
      expect(find.text('On my way'), findsOneWidget);
    });

    testWidgets('a live message appears without a refresh', (tester) async {
      final server = FakeChatServer();
      final id = server.seedThread(memberId: 2, name: 'Dita');
      final realtime = FakeRealtime();

      final chat = await _controller(server, realtime);
      await chat.load();
      await _pump(tester, chat, ChatScreen(conversationId: id));

      expect(find.text('Just landed'), findsNothing);

      realtime.deliver(id, {
        'id': '99',
        'body': 'Just landed',
        'author': {'id': 2, 'name': 'Dita'},
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      await tester.pumpAndSettle();

      expect(find.text('Just landed'), findsOneWidget);
    });

    testWidgets('a refused message says so', (tester) async {
      final server = FakeChatServer();
      final id = server.seedThread(memberId: 2, name: 'Dita');
      server.failSends = true;

      final chat = await _controller(server, FakeRealtime());
      await chat.load();
      await _pump(tester, chat, ChatScreen(conversationId: id));

      await tester.enterText(find.byType(TextField), 'On my way');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(AppIcons.send));
      await tester.pumpAndSettle();

      expect(find.text('That message did not send.'), findsOneWidget);
    });
  });
}
