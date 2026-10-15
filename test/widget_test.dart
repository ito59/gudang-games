import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/data/mock_data.dart';
import 'package:bandar_games/main.dart';
import 'package:bandar_games/theme/app_colors.dart';
import 'package:bandar_games/theme/app_icons.dart';
import 'package:bandar_games/theme/app_theme.dart';
import 'package:bandar_games/widgets/category_card.dart';
import 'package:bandar_games/widgets/game_card.dart';
import 'package:bandar_games/widgets/glass_panel.dart';

import 'support/fake_games.dart';

void main() {
  testWidgets('home screen renders its main sections', (tester) async {
    await tester.pumpWidget(GudangGamesApp(gameRepository: fakeGameRepository()));

    // The wordmark is the brand image now, not text.
    expect(find.bySemanticsLabel('GudangGames'), findsOneWidget);
    // Nothing featured on the fake server: the bundled slide shows.
    expect(find.text(featuredGames.first.description), findsOneWidget);
    expect(find.text('FEATURED'), findsOneWidget);
    expect(find.text('Play Now'), findsOneWidget);

    // The lower sections sit below the fold in the test viewport. The page has
    // several scrollables (category strip, grid), so target the outer list.
    await tester.scrollUntilVisible(
      find.text('Popular Games'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Browse Categories'), findsOneWidget);
    // In the grid; the hero slide may show the same game.
    expect(
      find.descendant(
        of: find.byType(GameCard),
        matching: find.text('Neon Guardian'),
      ),
      findsOneWidget,
    );
    expect(find.text('4.9'), findsOneWidget);
  });

  testWidgets('category card content fills the card and stays centred', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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
    await tester.pumpWidget(GudangGamesApp(gameRepository: fakeGameRepository()));

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
