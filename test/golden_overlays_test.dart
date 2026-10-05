import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/main.dart';

import 'support/fake_games.dart';

/// Material 3 styles SnackBars and dialogs from `inverseSurface`, which is a
/// light colour in a dark scheme. These goldens pin the themed versions so a
/// white slab cannot come back unnoticed.

import 'support/fake_profile.dart';
import 'support/fonts.dart';
import 'support/images.dart';
import 'support/preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  testWidgets('snackbar', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    resetPreferences();
    final server = FakeProfileServer();
    final auth = await signedInAuth(server);

    await tester.pumpWidget(
      BandarGamesApp(
        gameRepository: fakeGameRepository(),
        auth: auth,
        profileController: await loadedProfile(server, auth),
      ),
    );
    await tester.pumpAndSettle();
    await precacheAllImages(tester);

    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/snackbar.png'),
    );
  });

  testWidgets('dialog', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    resetPreferences();
    final server = FakeProfileServer();
    final auth = await signedInAuth(server);

    await tester.pumpWidget(
      BandarGamesApp(
        gameRepository: fakeGameRepository(),
        auth: auth,
        profileController: await loadedProfile(server, auth),
      ),
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Rey Anandra'),
      'Changed',
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dialog.png'),
    );
  });
}
