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

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  testWidgets('community golden', (tester) async {
    tester.view.physicalSize = const Size(390, 1250);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The feed comes from the API, so the golden is pinned to a fake server
    // rather than to whatever the backend happens to hold.
    final server = FakeFeedServer();
    final auth = Auth(client: server.client);

    await tester.pumpWidget(
      ChatScope(
        notifier: ChatController(),
        child: AuthScope(
          notifier: auth,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: Scaffold(
              body: CommunityScreen(
                repository: FeedRepository(auth: auth, client: server.client),
                members: MemberRepository(auth: auth, client: server.client),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await precacheAllImages(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/community.png'),
    );
  });
}
