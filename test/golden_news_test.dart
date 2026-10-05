import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/screens/community_screen.dart';
import 'package:bandar_games/services/feed_repository.dart';
import 'package:bandar_games/services/member_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_feed.dart';
import 'support/fonts.dart';
import 'support/images.dart';

/// Announcements get their own goldens rather than a seat in the community
/// one: the card and the article are a different shape from a member's post,
/// and the community golden stays about the feed itself.
final _server = FakeFeedServer()..seedNews();
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

Future<void> _pumpFeed(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    _wrap(
      Scaffold(
        body: CommunityScreen(
          repository: FeedRepository(auth: _auth, client: _server.client),
          members: MemberRepository(auth: _auth, client: _server.client),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await precacheAllImages(tester);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  testWidgets('news card golden', (tester) async {
    await _pumpFeed(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/news_card.png'),
    );
  });

  testWidgets('article golden', (tester) async {
    await _pumpFeed(tester);

    await tester.tap(find.text('Season 2 lands next week'));
    await tester.pumpAndSettle();
    await precacheAllImages(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/article.png'),
    );
  });
}
