import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/models/featured_event.dart';
import 'package:bandar_games/models/game.dart';
import 'package:bandar_games/screens/game_detail_screen.dart';
import 'package:bandar_games/screens/home_screen.dart';
import 'package:bandar_games/services/game_repository.dart';

import 'support/fake_games.dart';
import 'support/scopes.dart';

Widget _app(GameRepository repository) {
  return wrapScreen(HomeScreen(repository: repository));
}

const _promoted = Game(
  title: 'Promoted Game',
  slug: 'promoted-game',
  category: 'ACTION',
  rating: 4.8,
  image: '',
  description: 'Flagged as featured in the admin panel.',
  playUrl: 'http://example.test/games/promoted-game/play/index.html',
);

void main() {
  testWidgets('a featured game appears in the slider', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(fakeGameRepository(
        games: const [_promoted],
        slides: const [
          FeaturedEvent(
            title: 'Promoted Game',
            description: 'Flagged as featured in the admin panel.',
            season: 'FEATURED',
            isLive: false,
            image: '',
            game: _promoted,
          ),
        ],
      )),
    );
    await tester.pumpAndSettle();

    expect(find.text('FEATURED'), findsOneWidget);
    // The bundled sample slides must not show once the backend answers.
    expect(find.text('Neon Vanguard: Ascension'), findsNothing);
  });

  testWidgets('the slider opens the game it promotes', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(fakeGameRepository(
        games: const [_promoted],
        slides: const [
          FeaturedEvent(
            title: 'Promoted Game',
            description: 'Flagged as featured.',
            season: 'FEATURED',
            isLive: false,
            image: '',
            game: _promoted,
          ),
        ],
      )),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play Now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(GameDetailScreen), findsOneWidget);
  });

  testWidgets('an empty carousel falls back to the bundled slides', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Nothing featured yet: the hero must not be left blank.
    await tester.pumpWidget(_app(fakeGameRepository(games: const [_promoted])));
    await tester.pumpAndSettle();

    expect(find.text('Neon Vanguard: Ascension'), findsOneWidget);
  });
}
