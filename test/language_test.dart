import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/l10n/language.dart';
import 'package:bandar_games/main.dart';
import 'package:bandar_games/utils/time_format.dart';

import 'support/fake_games.dart';
import 'support/preferences.dart';

void main() {
  // The rest of the suite runs in English (see flutter_test_config.dart);
  // these tests put the real default back.
  setUp(() {
    resetPreferences();
    LanguageController.defaultLanguage = AppLanguage.id;
  });
  tearDown(() {
    LanguageController.defaultLanguage = AppLanguage.en;
    AppLanguage.current = AppLanguage.en;
  });

  testWidgets('the app opens in Indonesian', (tester) async {
    await tester.pumpWidget(
      GudangGamesApp(gameRepository: fakeGameRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Main Sekarang'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(AppLanguage.current, AppLanguage.id);
  });

  testWidgets('switching to English from the profile page sticks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final language = LanguageController();
    await tester.pumpWidget(
      GudangGamesApp(gameRepository: fakeGameRepository(), language: language),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Bahasa ·'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // The nav bar and the page behind the sheet switch without a restart.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Beranda'), findsNothing);
    expect(find.textContaining('Language ·'), findsOneWidget);

    // And a fresh start reads it back.
    final reloaded = LanguageController();
    await reloaded.load();
    expect(reloaded.language, AppLanguage.en);
  });

  test('dates follow the language', () {
    final now = DateTime(2026, 5, 20, 12);

    AppLanguage.current = AppLanguage.id;
    expect(TimeFormat.daySeparator(now, now: now), 'Hari ini');
    expect(
      TimeFormat.daySeparator(DateTime(2026, 5, 1), now: now),
      '1 Mei 2026',
    );

    AppLanguage.current = AppLanguage.en;
    expect(TimeFormat.daySeparator(now, now: now), 'Today');
    expect(
      TimeFormat.daySeparator(DateTime(2026, 5, 1), now: now),
      '1 May 2026',
    );
  });
}
