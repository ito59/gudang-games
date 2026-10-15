import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/screens/privacy_screen.dart';
import 'package:bandar_games/screens/web_page_screen.dart';
import 'package:bandar_games/services/api_config.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fonts.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const PrivacyScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  group('ApiConfig.page', () {
    test('asks the site for the phone\'s language when it has it', () {
      expect(
        ApiConfig.page('policy', language: 'id').toString(),
        '${ApiConfig.baseUrl}/policy?lang=id&theme=dark',
      );
      // Anything the site does not have falls back to English.
      expect(ApiConfig.page('terms', language: 'fr').queryParameters, {
        'lang': 'en',
        'theme': 'dark',
      });
    });

    test('a section lands on its heading', () {
      expect(
        ApiConfig.page('policy', section: 'delete').toString(),
        '${ApiConfig.baseUrl}/policy?lang=en&theme=dark#delete',
      );
    });
  });

  testWidgets('privacy golden', (tester) async {
    await _pump(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/privacy.png'),
    );
  });

  for (final (label, path, section) in [
    ('Privacy Policy', '/policy', ''),
    ('Terms of Service', '/terms', ''),
    ('Delete account', '/policy', 'delete'),
  ]) {
    testWidgets('$label opens its page inside the app', (tester) async {
      await _pump(tester);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      final page = tester.widget<WebPageScreen>(find.byType(WebPageScreen));
      expect(page.title, label);
      expect(page.url.path, path);
      expect(page.url.fragment, section);
      expect(page.url.queryParameters['lang'], isIn(['en', 'id']));

      // No WebView in widget tests: the page says so rather than crashing,
      // and the header still leads back.
      expect(find.text(label), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyScreen), findsOneWidget);
    });
  }
}
