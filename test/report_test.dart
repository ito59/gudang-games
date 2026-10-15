import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/main.dart';
import 'package:bandar_games/screens/chat_screen.dart';
import 'package:bandar_games/services/chat_repository.dart';
import 'package:bandar_games/services/feed_repository.dart';
import 'package:bandar_games/services/member_repository.dart';
import 'package:bandar_games/services/report_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';
import 'package:bandar_games/theme/app_icons.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_chat.dart';
import 'support/fake_feed.dart';
import 'support/fake_games.dart';
import 'support/preferences.dart';

/// Reporting, from each of the four places it is offered.
///
/// Every test asserts what reached the server, not just what the sheet said:
/// a report button that shows a thank-you and files nothing is worse than no
/// button at all.
late FakeFeedServer feed;
late Auth auth;

Future<void> _pumpApp(WidgetTester tester, {FakeChatServer? chat}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  resetPreferences();
  feed = FakeFeedServer();
  auth = Auth(client: feed.client);
  await auth.signIn(email: 'a@b.c', password: 'x');

  await tester.pumpWidget(
    GudangGamesApp(
      gameRepository: fakeGameRepository(),
      feedRepository: FeedRepository(auth: auth, client: feed.client),
      memberRepository: MemberRepository(auth: auth, client: feed.client),
      reportRepository: ReportRepository(auth: auth, client: feed.client),
      chatRepository: ChatRepository(
        auth: auth,
        client: (chat ?? FakeChatServer()).client,
      ),
      realtime: FakeRealtime(),
      auth: auth,
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Community'));
  await tester.pumpAndSettle();
}

/// Picks a reason and sends, from an open report sheet.
Future<void> _file(WidgetTester tester, String reason) async {
  expect(find.text('Send report'), findsOneWidget);

  await tester.tap(find.text(reason));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Send report'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a post is reported from its More menu', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();
    expect(find.text('Report this post'), findsOneWidget);

    await tester.tap(find.text('Report this post'));
    await tester.pumpAndSettle();

    await _file(tester, 'Spam or scam');

    expect(feed.reports, hasLength(1));
    expect(feed.reports.single['type'], 'post');
    expect(feed.reports.single['id'], 1);
    expect(feed.reports.single['reason'], 'spam');
    expect(find.text('Thanks — a moderator will look at it.'), findsOneWidget);
  });

  testWidgets('the note reaches the server with the report', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report this post'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'third time today');
    await _file(tester, 'Harassment or bullying');

    expect(feed.reports.single['note'], 'third time today');
    expect(feed.reports.single['reason'], 'harassment');
  });

  /// A report with no reason is a queue entry nobody can act on.
  testWidgets('nothing is sent until a reason is picked', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report this post'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();

    expect(feed.reports, isEmpty);
    // Still open, rather than closing as though something happened.
    expect(find.text('Send report'), findsOneWidget);
  });

  testWidgets('a member is reported from their sheet', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Dita'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report Dita Prameswari'));
    await tester.pumpAndSettle();

    await _file(tester, 'Something else');

    expect(feed.reports.single['type'], 'user');
    expect(feed.reports.single['id'], 2);
    expect(feed.reports.single['reason'], 'other');
  });

  testWidgets('a comment is reported by holding it', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byIcon(AppIcons.modeComment).first);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('That last hit was clean.'));
    await tester.pumpAndSettle();

    await _file(tester, 'Spam or scam');

    expect(feed.reports.single['type'], 'comment');
    expect(feed.reports.single['id'], 11);
  });

  testWidgets('a chat message is reported by holding it', (tester) async {
    final chatServer = FakeChatServer();
    final id = chatServer.seedThread(memberId: 2, name: 'Dita');
    chatServer.seedMessage(id, 'you are terrible', authorId: 2);

    resetPreferences();
    feed = FakeFeedServer();
    auth = Auth(client: feed.client);
    await auth.signIn(email: 'a@b.c', password: 'x');

    final chat = ChatController(
      repository: ChatRepository(auth: auth, client: chatServer.client),
      realtime: FakeRealtime(),
      auth: auth,
    );
    await chat.load();

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChatScope(
        notifier: chat,
        child: AuthScope(
          notifier: auth,
          child: MaterialApp(
            theme: AppTheme.light,
            home: ChatScreen(
              conversationId: id,
              reports: ReportRepository(auth: auth, client: feed.client),
              members: MemberRepository(auth: auth, client: feed.client),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('you are terrible'));
    await tester.pumpAndSettle();
    expect(find.text('Report this message'), findsOneWidget);

    await tester.tap(find.text('Report this message'));
    await tester.pumpAndSettle();

    await _file(tester, 'Harassment or bullying');

    expect(feed.reports.single['type'], 'message');
    expect(feed.reports.single['id'], 1);
  });

  /// Nothing to report about something you wrote yourself.
  testWidgets('one\'s own messages offer no report menu', (tester) async {
    final chatServer = FakeChatServer();
    final id = chatServer.seedThread(memberId: 2, name: 'Dita');
    chatServer.seedMessage(id, 'mine to own', authorId: 1);

    resetPreferences();
    feed = FakeFeedServer();
    auth = Auth(client: feed.client);
    await auth.signIn(email: 'a@b.c', password: 'x');

    final chat = ChatController(
      repository: ChatRepository(auth: auth, client: chatServer.client),
      realtime: FakeRealtime(),
      auth: auth,
    );
    await chat.load();

    await tester.pumpWidget(
      ChatScope(
        notifier: chat,
        child: AuthScope(
          notifier: auth,
          child: MaterialApp(
            theme: AppTheme.light,
            home: ChatScreen(
              conversationId: id,
              reports: ReportRepository(auth: auth, client: feed.client),
              members: MemberRepository(auth: auth, client: feed.client),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('mine to own'));
    await tester.pumpAndSettle();

    expect(find.text('Report this message'), findsNothing);
  });
}
