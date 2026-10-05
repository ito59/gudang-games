import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/screens/blocked_accounts_screen.dart';
import 'package:bandar_games/screens/community_screen.dart';
import 'package:bandar_games/services/feed_repository.dart';
import 'package:bandar_games/services/member_repository.dart';
import 'package:bandar_games/services/report_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_feed.dart';
import 'support/fonts.dart';

/// The surfaces moderation adds, at the height they ship at.
final _server = FakeFeedServer();
final _auth = Auth(client: _server.client);

Widget _wrap(Widget child) {
  return ChatScope(
    notifier: ChatController(),
    child: AuthScope(
      notifier: _auth,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: child,
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  // Signed in: reporting and blocking both need an account, and signed out
  // the sheet gives way to a sign-in prompt.
  setUp(() async {
    await _auth.signIn(email: 'you@test', password: 'secret');
  });

  void sizeToHandset(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpFeed(WidgetTester tester) async {
    sizeToHandset(tester);

    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: CommunityScreen(
            repository: FeedRepository(auth: _auth, client: _server.client),
            members: MemberRepository(auth: _auth, client: _server.client),
            reports: ReportRepository(auth: _auth, client: _server.client),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('post actions golden', (tester) async {
    await pumpFeed(tester);

    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/post_actions.png'),
    );
  });

  testWidgets('report sheet golden', (tester) async {
    await pumpFeed(tester);

    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report this post'));
    await tester.pumpAndSettle();

    // With a reason chosen, so the selected state is in the picture too.
    await tester.tap(find.text('Harassment or bullying'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/report_sheet.png'),
    );
  });

  testWidgets('block confirmation golden', (tester) async {
    await pumpFeed(tester);

    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block Dita Prameswari'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/block_confirm.png'),
    );
  });

  testWidgets('blocked accounts golden', (tester) async {
    sizeToHandset(tester);
    _server.blocked.add(2);
    addTearDown(() => _server.blocked.clear());

    await tester.pumpWidget(
      _wrap(
        BlockedAccountsScreen(
          members: MemberRepository(auth: _auth, client: _server.client),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/blocked_accounts.png'),
    );
  });
}
