import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/data/mock_data.dart';
import 'package:bandar_games/main.dart';
import 'package:bandar_games/theme/app_colors.dart';
import 'package:bandar_games/theme/app_icons.dart';
import 'package:bandar_games/theme/app_theme.dart';
import 'package:bandar_games/widgets/category_card.dart';
import 'package:bandar_games/widgets/game_card.dart';

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

    // The category menu sits at the top, under the header.
    expect(find.text('All'), findsOneWidget);

    // The game list sits below the fold in the test viewport. The slider is
    // a scrollable too, so target the outer list.
    // In the list; the featured slide shows the same game.
    final row = find.descendant(
      of: find.byType(GameCard),
      matching: find.text('Neon Guardian'),
    );
    await tester.scrollUntilVisible(
      row,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Popular Games'), findsOneWidget);
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: find.byType(GameCard), matching: find.text('4.9')),
      findsOneWidget,
    );
  });

  testWidgets('category tile keeps its icon centred over the label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 90,
              child: CategoryCard(category: gameCategories.first),
            ),
          ),
        ),
      ),
    );

    final tile = tester.getRect(find.byType(CategoryCard));
    final icon = tester.getRect(find.byType(Icon));
    final label = tester.getRect(find.text(gameCategories.first.label));

    expect(icon.center.dx, closeTo(tile.center.dx, 0.5));
    expect(label.center.dx, closeTo(tile.center.dx, 0.5));
    expect(label.top, greaterThan(icon.bottom));
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
