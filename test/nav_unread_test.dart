import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/main.dart';
import 'package:bandar_games/screens/chat_screen.dart';
import 'package:bandar_games/services/chat_repository.dart';
import 'package:bandar_games/services/feed_repository.dart';
import 'package:bandar_games/services/member_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';

import 'support/fake_chat.dart';
import 'support/fake_feed.dart';
import 'support/fake_games.dart';
import 'support/preferences.dart';

/// The dot on a tab. Not `bySemanticsLabel`: it is drawn beside an icon, and
/// what matters is the marker's own label rather than a merged node.
final _unreadDot = find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == 'unread',
);

Future<FakeRealtime> _pumpApp(WidgetTester tester, FakeChatServer chat) async {
  resetPreferences();
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final feed = FakeFeedServer();
  final auth = Auth(client: chat.client);
  expect(await auth.signIn(email: 'a@b.c', password: 'x'), isNull);
  final realtime = FakeRealtime();

  await tester.pumpWidget(
    GudangGamesApp(
      gameRepository: fakeGameRepository(),
      feedRepository: FeedRepository(auth: auth, client: feed.client),
      memberRepository: MemberRepository(auth: auth, client: feed.client),
      chatRepository: ChatRepository(auth: auth, client: chat.client),
      realtime: realtime,
      auth: auth,
    ),
  );
  await tester.pumpAndSettle();
  return realtime;
}

void main() {
  testWidgets('nothing waiting means no dot', (tester) async {
    final chat = FakeChatServer()..seedThread(memberId: 2, name: 'Dita');

    await _pumpApp(tester, chat);

    expect(_unreadDot, findsNothing);
  });

  testWidgets('a thread with unread messages marks the Community tab', (
    tester,
  ) async {
    final chat = FakeChatServer();
    final id = chat.seedThread(memberId: 2, name: 'Dita', unread: 2);
    chat.seedMessage(id, 'Are you on later?', authorId: 2);

    await _pumpApp(tester, chat);

    // Still on Home — the whole point is knowing without going to look.
    expect(find.text('Popular Games'), findsOneWidget);
    expect(_unreadDot, findsOneWidget);
  });

  testWidgets('a message arriving while on another tab raises the dot', (
    tester,
  ) async {
    final chat = FakeChatServer();
    final id = chat.seedThread(memberId: 2, name: 'Dita');

    final realtime = await _pumpApp(tester, chat);
    expect(_unreadDot, findsNothing);

    realtime.deliver(id, {
      'id': '99',
      'body': 'You around?',
      'author': {'id': 2, 'name': 'Dita'},
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await tester.pumpAndSettle();

    expect(_unreadDot, findsOneWidget);
  });

  testWidgets('reading the thread clears the dot', (tester) async {
    final chat = FakeChatServer();
    final id = chat.seedThread(memberId: 2, name: 'Dita', unread: 1);
    chat.seedMessage(id, 'Are you on later?', authorId: 2);

    await _pumpApp(tester, chat);
    expect(_unreadDot, findsOneWidget);

    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Messages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dita'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(_unreadDot, findsNothing);
  });

  testWidgets('the dot does not shift the tabs sideways', (tester) async {
    final chat = FakeChatServer();
    final id = chat.seedThread(memberId: 2, name: 'Dita');

    final realtime = await _pumpApp(tester, chat);
    final before = tester.getCenter(find.text('Profile'));

    realtime.deliver(id, {
      'id': '99',
      'body': 'You around?',
      'author': {'id': 2, 'name': 'Dita'},
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await tester.pumpAndSettle();

    // A message arriving must not make the bar rearrange itself.
    expect(tester.getCenter(find.text('Profile')), before);
  });
}
