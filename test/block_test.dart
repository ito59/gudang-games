import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/main.dart';
import 'package:bandar_games/screens/blocked_accounts_screen.dart';
import 'package:bandar_games/services/chat_repository.dart';
import 'package:bandar_games/services/feed_repository.dart';
import 'package:bandar_games/services/member_repository.dart';
import 'package:bandar_games/services/report_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_chat.dart';
import 'support/fake_feed.dart';
import 'support/fake_games.dart';
import 'support/preferences.dart';

/// Blocking, from the member sheet and from a post, and the list that makes
/// it undoable.
///
/// The server decides what a block hides; these tests check the app asks for
/// it, acts on the answer, and never claims a block that did not save.
late FakeFeedServer feed;
late Auth auth;

Future<void> _pumpCommunity(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  resetPreferences();
  auth = Auth(client: feed.client);
  await auth.signIn(email: 'a@b.c', password: 'x');

  await tester.pumpWidget(
    GudangGamesApp(
      gameRepository: fakeGameRepository(),
      feedRepository: FeedRepository(auth: auth, client: feed.client),
      memberRepository: MemberRepository(auth: auth, client: feed.client),
      reportRepository: ReportRepository(auth: auth, client: feed.client),
      chatRepository: ChatRepository(auth: auth, client: FakeChatServer().client),
      realtime: FakeRealtime(),
      auth: auth,
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Community'));
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester) async {
  expect(find.textContaining('Block Dita Prameswari?'), findsOneWidget);
  await tester.tap(find.widgetWithText(TextButton, 'Block'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => feed = FakeFeedServer());

  testWidgets('blocking from the member sheet asks first', (tester) async {
    await _pumpCommunity(tester);

    await tester.tap(find.text('Dita'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Block Dita Prameswari'));
    await tester.pumpAndSettle();

    // Blocking ends a thread and a friendship, so it is never one tap.
    expect(find.textContaining('They are not told.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(feed.blocked, isEmpty);
  });

  testWidgets('a blocked member and their posts leave the screen', (
    tester,
  ) async {
    await _pumpCommunity(tester);

    expect(find.text('Cleared the Mystic Ruin raid on the first try.'),
        findsOneWidget);

    await tester.tap(find.text('Dita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block Dita Prameswari'));
    await tester.pumpAndSettle();
    await _confirm(tester);

    expect(feed.blocked, contains(2));
    expect(feed.calls, contains('POST /api/v1/members/2/block'));
    // Reloaded, not merely hidden locally: the strip and the feed both come
    // back without them.
    expect(find.text('Dita'), findsNothing);
    expect(
      find.text('Cleared the Mystic Ruin raid on the first try.'),
      findsNothing,
    );
    expect(find.text('Dita Prameswari is blocked.'), findsOneWidget);
  });

  testWidgets('blocking a post author takes their posts off the feed', (
    tester,
  ) async {
    await _pumpCommunity(tester);

    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Block Dita Prameswari'));
    await tester.pumpAndSettle();
    await _confirm(tester);

    expect(feed.blocked, contains(2));
    expect(
      find.text('Cleared the Mystic Ruin raid on the first try.'),
      findsNothing,
    );
    // Somebody else's post is untouched.
    expect(find.text('Looking for two more for tonight.'), findsOneWidget);
  });

  testWidgets('the blocked list shows who is blocked and undoes it', (
    tester,
  ) async {
    feed.blocked.add(2);

    resetPreferences();
    auth = Auth(client: feed.client);
    await auth.signIn(email: 'a@b.c', password: 'x');

    await tester.pumpWidget(
      AuthScope(
        notifier: auth,
        child: MaterialApp(
          theme: AppTheme.light,
          home: BlockedAccountsScreen(
            members: MemberRepository(auth: auth, client: feed.client),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dita Prameswari'), findsOneWidget);

    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();

    expect(feed.blocked, isEmpty);
    expect(feed.calls, contains('DELETE /api/v1/members/2/block'));
    // Off the list at once — this screen is only the blocked ones.
    expect(find.text('Dita Prameswari'), findsNothing);
    expect(find.text('You have not blocked anyone.'), findsOneWidget);
  });

  testWidgets('an empty list says so rather than looking broken', (
    tester,
  ) async {
    resetPreferences();
    auth = Auth(client: feed.client);
    await auth.signIn(email: 'a@b.c', password: 'x');

    await tester.pumpWidget(
      AuthScope(
        notifier: auth,
        child: MaterialApp(
          theme: AppTheme.light,
          home: BlockedAccountsScreen(
            members: MemberRepository(auth: auth, client: feed.client),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You have not blocked anyone.'), findsOneWidget);
  });
}
