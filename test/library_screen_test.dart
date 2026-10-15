import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:bandar_games/main.dart';
import 'package:bandar_games/models/game.dart';
import 'package:bandar_games/screens/library_screen.dart';
import 'package:bandar_games/state/play_history.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_games.dart';

Game _game(String title, String slug) => Game(
  title: title,
  slug: slug,
  category: 'ACTION',
  rating: 4.5,
  image: '',
  playUrl: 'http://example.test/$slug/play/index.html',
);

Widget _library(PlayHistory history) {
  return PlayHistoryScope(
    notifier: history,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: LibraryScreen()),
    ),
  );
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty());

  testWidgets('an untouched library explains itself', (tester) async {
    final history = PlayHistory();
    await history.load();

    await tester.pumpWidget(_library(history));
    await tester.pumpAndSettle();

    expect(find.text('Nothing played yet'), findsOneWidget);
  });

  testWidgets('played games are listed most played first', (tester) async {
    final history = PlayHistory();
    await history.load();

    await history.record(_game('Rarely Played', 'rare'));
    await history.record(_game('Often Played', 'often'));
    await history.record(_game('Often Played', 'often'));
    await history.record(_game('Often Played', 'often'));
    await history.record(_game('Sometimes Played', 'sometimes'));
    await history.record(_game('Sometimes Played', 'sometimes'));

    await tester.pumpWidget(_library(history));
    await tester.pumpAndSettle();

    // The row reads "3 plays · now", so match the count within it.
    expect(find.textContaining('3 plays'), findsOneWidget);
    expect(find.textContaining('2 plays'), findsOneWidget);
    // Singular for one, so a row never reads "1 plays".
    expect(find.textContaining('1 play ·'), findsOneWidget);

    // Rank order on screen, top to bottom.
    final titles = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where((t) => t != null && t.endsWith('Played'))
        .toList();
    expect(titles, ['Often Played', 'Sometimes Played', 'Rarely Played']);
  });

  testWidgets('playing a game from the app adds it to the library', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GudangGamesApp(
        gameRepository: fakeGameRepository(
          games: [_game('Star Wars', 'star-wars')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Library starts empty.
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing played yet'), findsOneWidget);

    // Play it.
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Star Wars'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Star Wars'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play Game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Back out of the player, then the detail page.
    await tester.tap(find.byTooltip('Back').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing played yet'), findsNothing);
    expect(find.textContaining('1 play ·'), findsOneWidget);
  });
}
