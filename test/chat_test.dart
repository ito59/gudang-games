import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/main.dart';
import 'package:bandar_games/screens/chat_screen.dart';
import 'package:bandar_games/services/chat_repository.dart';
import 'package:bandar_games/services/feed_repository.dart';
import 'package:bandar_games/services/member_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_chat.dart';
import 'support/fake_feed.dart';
import 'support/fake_games.dart';
import 'support/preferences.dart';

/// The session [_chatController] last built, for the screens that need one.
late Auth auth;

/// A chat controller wired to [server], already signed in.
Future<ChatController> _chatController(FakeChatServer server) async {
  resetPreferences();
  auth = Auth(client: server.client);
  await auth.signIn(email: 'a@b.c', password: 'x');

  return ChatController(
    repository: ChatRepository(auth: auth, client: server.client),
    realtime: FakeRealtime(),
    auth: auth,
  );
}

Future<void> _pumpThread(
  WidgetTester tester,
  ChatController chat,
  String id,
) async {
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

/// The whole app with every server behind a fake. The community page reaches
/// for the feed, the member strip and — once somebody taps Message — chat.
Widget _app(FakeChatServer chat) {
  final feed = FakeFeedServer();
  final auth = Auth(client: feed.client);

  return BandarGamesApp(
    gameRepository: fakeGameRepository(),
    feedRepository: FeedRepository(auth: auth, client: feed.client),
    memberRepository: MemberRepository(auth: auth, client: feed.client),
    chatRepository: ChatRepository(auth: auth, client: chat.client),
    realtime: FakeRealtime(),
    auth: auth,
  );
}

void main() {
  group('chat screen', () {
    testWidgets('the thread is broken up by day', (tester) async {
      final server = FakeChatServer();
      final id = server.seedThread(memberId: 2, name: 'Dita');
      final now = DateTime.now();
      server.seedMessage(
        id,
        'Yesterday',
        authorId: 2,
        at: now.subtract(const Duration(days: 1)),
      );
      server.seedMessage(id, 'Today', authorId: 2, at: now);

      final chat = await _chatController(server);
      await chat.load();
      await _pumpThread(tester, chat, id);

      expect(find.text('Yesterday'), findsWidgets);
      expect(find.text('Today'), findsWidgets);
    });

    testWidgets('an empty thread invites the first message', (tester) async {
      final server = FakeChatServer();
      final id = server.seedThread(memberId: 2, name: 'Kirana Ayu');

      final chat = await _chatController(server);
      await chat.load();
      await _pumpThread(tester, chat, id);

      expect(
        find.textContaining('No messages with Kirana Ayu yet'),
        findsOneWidget,
      );
    });
  });

  group('from community', () {
    testWidgets('choosing Message opens the thread with that member', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final chat = FakeChatServer();
      // Bagas is member 3 in the feed fake.
      final id = chat.seedThread(memberId: 3, name: 'Bagas Wirawan');
      chat.seedMessage(id, 'Time trial squad still needs one. You in?', authorId: 3);

      await tester.pumpWidget(_app(chat));
      await tester.tap(find.text('Community'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bagas'));
      await tester.pumpAndSettle();
      // The member sheet stands between the tap and the thread.
      await tester.tap(find.text('Message'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(
        find.text('Time trial squad still needs one. You in?'),
        findsOneWidget,
      );
    });

    testWidgets('messaging someone new opens a thread on the server', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final chat = FakeChatServer();

      await tester.pumpWidget(_app(chat));
      await tester.tap(find.text('Community'));
      await tester.pumpAndSettle();

      // Ilham has no thread yet.
      await tester.scrollUntilVisible(
        find.text('Ilham'),
        100,
        scrollable: find.byType(Scrollable).at(1),
      );
      await tester.tap(find.text('Ilham'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Message'));
      await tester.pumpAndSettle();

      expect(chat.calls, contains('POST /api/v1/conversations'));
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.textContaining('No messages with'), findsOneWidget);
    });
  });
}
