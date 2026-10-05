import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/data/mock_data.dart';
import 'package:bandar_games/main.dart';
import 'package:bandar_games/theme/app_colors.dart';
import 'package:bandar_games/theme/app_icons.dart';
import 'package:bandar_games/theme/app_theme.dart';
import 'package:bandar_games/widgets/category_card.dart';
import 'package:bandar_games/widgets/glass_panel.dart';

import 'support/fake_games.dart';

void main() {
  testWidgets('home screen renders its main sections', (tester) async {
    await tester.pumpWidget(BandarGamesApp(gameRepository: fakeGameRepository()));

    // The wordmark is the brand image now, not text.
    expect(find.bySemanticsLabel('BandarGames'), findsOneWidget);
    expect(find.text('Neon Vanguard: Ascension'), findsOneWidget);
    expect(find.text('LIVE EVENT'), findsOneWidget);
    expect(find.text('Play Now'), findsOneWidget);

    // The lower sections sit below the fold in the test viewport. The page has
    // several scrollables (category strip, grid), so target the outer list.
    await tester.scrollUntilVisible(
      find.text('Popular Games'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Browse Categories'), findsOneWidget);
    expect(find.text('Neon Guardian'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
  });

  testWidgets('category card content fills the card and stays centred', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(child: CategoryCard(category: gameCategories.first)),
        ),
      ),
    );

    final card = tester.getRect(find.byType(GlassPanel));
    final content = tester.getRect(find.byType(Column).first);
    final circle = tester.getRect(
      find
          .ancestor(of: find.byType(Icon), matching: find.byType(Container))
          .first,
    );

    // A loose Stack fit used to shrink the content to its intrinsic width and
    // pin it to the top-left, pulling the icon off centre.
    expect(content.width, card.width);
    expect(circle.center.dx, card.center.dx);
  });

  testWidgets('tapping a nav destination updates the selection', (
    tester,
  ) async {
    await tester.pumpWidget(BandarGamesApp(gameRepository: fakeGameRepository()));

    Icon iconFor(IconData data) =>
        tester.widget<Icon>(find.byIcon(data).first);

    expect(iconFor(AppIcons.home).color, AppColors.primary);
    expect(iconFor(AppIcons.home).fill, 1);
    expect(iconFor(AppIcons.sportsEsports).color, AppColors.onSurfaceVariant);

    await tester.tap(find.text('Library'));
    await tester.pump();

    expect(iconFor(AppIcons.sportsEsports).color, AppColors.primary);
    expect(iconFor(AppIcons.home).color, AppColors.onSurfaceVariant);
  });
}
