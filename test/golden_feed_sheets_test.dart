import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/screens/community_screen.dart';
import 'package:bandar_games/screens/sign_in_screen.dart';
import 'package:bandar_games/services/feed_repository.dart';
import 'package:bandar_games/services/member_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';
import 'package:bandar_games/theme/app_icons.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_feed.dart';
import 'support/fake_google.dart';
import 'support/fonts.dart';

final _server = FakeFeedServer();
final _auth = Auth(client: _server.client);

Widget _wrap(Widget child) {
  return ChatScope(
    notifier: ChatController(),
    child: AuthScope(
      notifier: _auth,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
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

  // The goldens are taken signed in, which is the state that can write —
  // otherwise a write prompts for sign-in and the sheet never opens.
  setUp(() async {
    await _auth.signIn(email: 'you@test', password: 'secret');
  });

  Future<void> pumpFeed(WidgetTester tester) async {
    // A real handset, so the sheets are judged at the height they ship at.
    tester.view.physicalSize = const Size(390, 844);
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
  }

  testWidgets('post composer golden', (tester) async {
    await pumpFeed(tester);

    await tester.tap(find.byTooltip('New post'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Cleared it on the first try.');
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/post_composer.png'),
    );
  });

  testWidgets('comments sheet golden', (tester) async {
    await pumpFeed(tester);

    await tester.tap(find.byIcon(AppIcons.modeComment).first);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/comments_sheet.png'),
    );
  });

  testWidgets('sign in with google golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // A build that has its OAuth client IDs, which is what ships.
    final auth = Auth(
      client: _server.client,
      google: FakeGoogleAuthenticator(),
    );

    await tester.pumpWidget(
      ChatScope(
        notifier: ChatController(),
        child: AuthScope(
          notifier: auth,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const SignInScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sign_in_google.png'),
    );
  });

  testWidgets('sign in unconfigured golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // A debug build with no client ID yet: what a developer sees mid-setup.
    await tester.pumpWidget(
      ChatScope(
        notifier: ChatController(),
        child: AuthScope(
          notifier: Auth(
            client: _server.client,
            google: FakeGoogleAuthenticator(configured: false),
          ),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const SignInScreen(showUnconfiguredGoogle: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sign_in_unconfigured.png'),
    );
  });

  testWidgets('sign in golden', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // A release build with Google unconfigured: the email form on its own.
    await tester.pumpWidget(
      _wrap(const SignInScreen(showUnconfiguredGoogle: false)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sign_in.png'),
    );
  });
}
