import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/screens/community_screen.dart';
import 'package:bandar_games/screens/member_profile_screen.dart';
import 'package:bandar_games/services/feed_repository.dart';
import 'package:bandar_games/services/member_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_feed.dart';
import 'support/fonts.dart';
import 'support/images.dart';

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

  testWidgets('member sheet golden', (tester) async {
    tester.view.physicalSize = const Size(390, 780);
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

    await tester.tap(find.text('Dita'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/member_sheet.png'),
    );
  });

  testWidgets('member profile golden', (tester) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        MemberProfileScreen(
          memberId: 2,
          repository: FeedRepository(auth: _auth, client: _server.client),
          members: MemberRepository(auth: _auth, client: _server.client),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await precacheAllImages(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/member_profile.png'),
    );
  });
}
