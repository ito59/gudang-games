import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/models/game.dart';
import 'package:bandar_games/models/game_category.dart';
import 'package:bandar_games/screens/home_screen.dart';
import 'package:bandar_games/theme/app_icons.dart';

import 'support/fake_games.dart';
import 'support/scopes.dart';

const _categories = [
  GameCategory(label: 'Action', slug: 'action', icon: AppIcons.swords),
  GameCategory(label: 'Arcade', slug: 'arcade', icon: AppIcons.speed),
  GameCategory(label: 'Puzzle', slug: 'puzzle', icon: AppIcons.chess),
];

const _games = [
  Game(
    title: 'Spiderman Rush',
    slug: 'spiderman',
    category: 'ACTION',
    categorySlug: 'action',
    rating: 4.5,
    image: '',
  ),
  Game(
    title: 'Word Blocks',
    slug: 'word-blocks',
    category: 'ARCADE',
    categorySlug: 'arcade',
    rating: 4.4,
    image: '',
  ),
  Game(
    title: 'Chocolate Chase',
    slug: 'chocolate',
    category: 'ARCADE',
    categorySlug: 'arcade',
    rating: 4.2,
    image: '',
  ),
];

Future<void> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    wrapScreen(
      HomeScreen(
        repository: fakeGameRepository(
          games: _games,
          categories: _categories,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Browse Categories'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('categories come from the backend', (tester) async {
    await _pumpHome(tester);

    // "Arcade" only exists on the backend, not in the bundled set.
    expect(find.text('Arcade'), findsOneWidget);
    expect(find.text('Puzzle'), findsOneWidget);
  });

  testWidgets('tapping a category filters the games', (tester) async {
    await _pumpHome(tester);

    expect(find.text('Spiderman Rush'), findsOneWidget);
    expect(find.text('Word Blocks'), findsOneWidget);

    await tester.tap(find.text('Arcade'));
    await tester.pumpAndSettle();

    expect(find.text('Word Blocks'), findsOneWidget);
    expect(find.text('Chocolate Chase'), findsOneWidget);
    expect(find.text('Spiderman Rush'), findsNothing);
  });

  testWidgets('tapping the active category clears the filter', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();
    expect(find.text('Word Blocks'), findsNothing);

    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();
    expect(find.text('Word Blocks'), findsOneWidget);
    expect(find.text('Spiderman Rush'), findsOneWidget);
  });

  testWidgets('an empty category offers a way back', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text('Puzzle'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No games in this category'), findsOneWidget);
    expect(find.text('Spiderman Rush'), findsNothing);

    await tester.tap(find.text('Show all games'));
    await tester.pumpAndSettle();

    expect(find.text('Spiderman Rush'), findsOneWidget);
  });
}
