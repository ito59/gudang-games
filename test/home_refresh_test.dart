import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/models/game.dart';
import 'package:bandar_games/models/game_category.dart';
import 'package:bandar_games/screens/home_screen.dart';
import 'package:bandar_games/theme/app_icons.dart';

import 'support/fake_games.dart';
import 'support/scopes.dart';

Game _game(String title) =>
    Game(title: title, category: 'ACTION', rating: 4.5, image: '');

Future<void> _pump(WidgetTester tester, FakeCatalogueServer server) async {
  // Tall enough that the games grid is laid out rather than left off-screen.
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    wrapScreen(HomeScreen(repository: server.repository)),
  );
  await tester.pumpAndSettle();
}

/// The gesture: drag the page down far enough to trip the indicator.
///
/// The outer list, not the category strip or the slider — those are ListViews
/// too, and flinging one of them scrolls sideways instead.
Future<void> _pullDown(WidgetTester tester) async {
  final page = find.descendant(
    of: find.byType(RefreshIndicator),
    matching: find.byType(ListView),
  );

  await tester.fling(page.first, const Offset(0, 400), 1200);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the home page can be pulled down', (tester) async {
    await _pump(tester, FakeCatalogueServer(games: [_game('Neon Guardian')]));

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('a game published since opening the app appears', (tester) async {
    final server = FakeCatalogueServer(games: [_game('Neon Guardian')]);
    await _pump(tester, server);

    expect(find.text('Neon Guardian'), findsOneWidget);
    expect(find.text('Mystic Ruin'), findsNothing);

    // Somebody adds one in the admin panel.
    server.games = [_game('Neon Guardian'), _game('Mystic Ruin')];

    await _pullDown(tester);

    expect(find.text('Mystic Ruin'), findsOneWidget);
  });

  testWidgets('a game unpublished since opening the app goes away', (
    tester,
  ) async {
    final server = FakeCatalogueServer(
      games: [_game('Neon Guardian'), _game('Mystic Ruin')],
    );
    await _pump(tester, server);
    expect(find.text('Mystic Ruin'), findsOneWidget);

    server.games = [_game('Neon Guardian')];
    await _pullDown(tester);

    expect(find.text('Mystic Ruin'), findsNothing);
  });

  testWidgets('the refresh asks for the whole catalogue, not just games', (
    tester,
  ) async {
    final server = FakeCatalogueServer(games: [_game('Neon Guardian')]);
    await _pump(tester, server);

    expect(server.callsTo('/games'), 1);
    expect(server.callsTo('/featured'), 1);
    expect(server.callsTo('/categories'), 1);

    await _pullDown(tester);

    // The slider and the category strip go stale too.
    expect(server.callsTo('/games'), 2);
    expect(server.callsTo('/featured'), 2);
    expect(server.callsTo('/categories'), 2);
  });

  testWidgets('a refresh that cannot reach the server says so', (tester) async {
    final server = FakeCatalogueServer(games: [_game('Neon Guardian')]);
    await _pump(tester, server);

    server.offline = true;
    await _pullDown(tester);

    // The bundled sample catalogue is what is on screen now, and the page
    // has to admit it rather than passing it off as live data.
    expect(find.textContaining('Showing sample'), findsOneWidget);
  });

  testWidgets('only categories the server offered are shown', (tester) async {
    // The backend leaves out categories with nothing in them, so a chip
    // never leads to an empty list. The app shows what it is given.
    final server = FakeCatalogueServer(
      games: [_game('Neon Guardian')],
      categories: const [
        GameCategory(label: 'Action', slug: 'action', icon: AppIcons.swords),
      ],
    );
    await _pump(tester, server);

    expect(find.text('Action'), findsOneWidget);
    expect(find.text('RPG'), findsNothing);
  });

  testWidgets('a category that empties out disappears on refresh', (
    tester,
  ) async {
    final server = FakeCatalogueServer(
      games: [_game('Neon Guardian')],
      categories: const [
        GameCategory(label: 'Action', slug: 'action', icon: AppIcons.swords),
        GameCategory(label: 'Racing', slug: 'racing', icon: AppIcons.speed),
      ],
    );
    await _pump(tester, server);
    expect(find.text('Racing'), findsOneWidget);

    // Its last game was unpublished, so the server stops offering it.
    server.categories = const [
      GameCategory(label: 'Action', slug: 'action', icon: AppIcons.swords),
    ];
    await _pullDown(tester);

    expect(find.text('Racing'), findsNothing);
    expect(find.text('Action'), findsOneWidget);
  });

  testWidgets('a chosen category survives the refresh', (tester) async {
    final server = FakeCatalogueServer(
      games: [
        Game(title: 'Neon Guardian', category: 'ACTION', categorySlug: 'action', rating: 4.9, image: ''),
        Game(title: 'Mystic Ruin', category: 'RPG', categorySlug: 'rpg', rating: 4.7, image: ''),
      ],
      categories: const [
        GameCategory(label: 'Action', slug: 'action', icon: AppIcons.swords),
        GameCategory(label: 'RPG', slug: 'rpg', icon: AppIcons.magicButton),
      ],
    );
    await _pump(tester, server);

    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();
    expect(find.text('Mystic Ruin'), findsNothing);

    await _pullDown(tester);

    // Pulling for new games must not silently drop the filter.
    expect(find.text('Neon Guardian'), findsOneWidget);
    expect(find.text('Mystic Ruin'), findsNothing);
  });
}
