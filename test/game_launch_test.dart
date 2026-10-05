import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/models/game.dart';
import 'package:bandar_games/screens/game_player_screen.dart';
import 'package:bandar_games/screens/game_detail_screen.dart';
import 'package:bandar_games/screens/home_screen.dart';
import 'package:bandar_games/screens/trailer_screen.dart';

import 'support/fake_games.dart';
import 'support/scopes.dart';

Widget _app(List<Game> games) {
  return wrapScreen(HomeScreen(repository: fakeGameRepository(games: games)));
}

Future<void> _tapGame(WidgetTester tester, String title) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text(title),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a trailer button appears only when there is a trailer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const [
        Game(
          title: 'With Trailer',
          category: 'ACTION',
          rating: 4,
          image: '',
          playUrl: 'http://example.test/play',
          trailerUrl: 'http://example.test/games/x/trailer',
        ),
        Game(
          title: 'No Trailer',
          category: 'RPG',
          rating: 4,
          image: '',
          playUrl: 'http://example.test/play',
        ),
      ]),
    );

    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('With Trailer'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // One button for one game with a trailer, not two.
    expect(find.text('Trailer'), findsOneWidget);
  });

  testWidgets('the trailer button opens the player, not the game', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const [
        Game(
          title: 'With Trailer',
          category: 'ACTION',
          rating: 4,
          image: '',
          playUrl: 'http://example.test/play',
          trailerUrl: 'http://example.test/games/x/trailer',
        ),
      ]),
    );

    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Trailer'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trailer'));
    // Let the route transition run; the player itself stays uninitialised
    // because there is no video plugin under test.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TrailerScreen), findsOneWidget);
    // Watching a trailer must never start the game.
    expect(find.byType(GamePlayerScreen), findsNothing);
  });

  testWidgets('tapping a card opens the detail page, not the game', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const [
        Game(
          title: 'Star Wars',
          slug: 'star-wars',
          category: 'ACTION',
          rating: 4.5,
          image: '',
          description: 'Rebels take on the Empire.',
          playsCount: 1234,
          isHosted: true,
          playUrl: 'http://example.test/games/star-wars/play/index.html',
        ),
      ]),
    );

    await _tapGame(tester, 'Star Wars');

    expect(find.byType(GameDetailScreen), findsOneWidget);
    // A browse tap must never start the game.
    expect(find.byType(GamePlayerScreen), findsNothing);

    // The metadata the page exists to show.
    expect(find.text('Rebels take on the Empire.'), findsOneWidget);
    expect(find.text('ACTION'), findsWidgets);
    expect(find.text('1.2k plays'), findsOneWidget);
    expect(find.text('Play Game'), findsOneWidget);
  });

  testWidgets('the detail page starts the game on demand', (tester) async {
    await tester.pumpWidget(
      _app(const [
        Game(
          title: 'Star Wars',
          slug: 'star-wars',
          category: 'ACTION',
          rating: 4.5,
          image: '',
          playUrl: 'http://example.test/games/star-wars/play/index.html',
        ),
      ]),
    );

    await _tapGame(tester, 'Star Wars');
    await tester.tap(find.text('Play Game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(GamePlayerScreen), findsOneWidget);
  });

  testWidgets('the detail page offers the trailer', (tester) async {
    await tester.pumpWidget(
      _app(const [
        Game(
          title: 'Star Wars',
          slug: 'star-wars',
          category: 'ACTION',
          rating: 4.5,
          image: '',
          playUrl: 'http://example.test/play',
          trailerUrl: 'http://example.test/games/star-wars/trailer',
        ),
      ]),
    );

    await _tapGame(tester, 'Star Wars');
    expect(find.text('Play Trailer'), findsOneWidget);

    await tester.tap(find.text('Play Trailer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TrailerScreen), findsOneWidget);
  });

  testWidgets('a game with no source cannot be played from its page', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const [
        Game(title: 'Unsourced', slug: 'x', category: 'RPG', rating: 3, image: ''),
      ]),
    );

    await _tapGame(tester, 'Unsourced');

    expect(find.byType(GameDetailScreen), findsOneWidget);
    expect(find.text('Play Game'), findsNothing);
    expect(find.textContaining('no playable source yet'), findsOneWidget);
  });
}
