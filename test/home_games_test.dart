import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bandar_games/screens/home_screen.dart';
import 'package:bandar_games/services/game_repository.dart';

import 'support/scopes.dart';

Widget _app(GameRepository repository) {
  return wrapScreen(HomeScreen(repository: repository));
}

GameRepository _repositoryReturning(Object body, {int status = 200}) {
  return GameRepository(
    client: MockClient((request) async {
      // Route by endpoint: answering /featured with the games payload would
      // turn every game into a carousel slide.
      if (request.url.path.endsWith('/featured')) {
        return http.Response(
          jsonEncode({'data': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
}

Future<void> _scrollToGames(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Popular Games'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('published games from the backend are listed', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(_repositoryReturning({
        'data': [
          {
            'id': 7,
            'title': 'Star Wars',
            'category': 'Action',
            'rating': 4.5,
            'source_type': 'zip',
          },
          {
            'id': 8,
            'title': 'Nested Build Game',
            'category': 'RPG',
            'rating': 4.2,
            'source_type': 'zip',
          },
        ],
      })),
    );
    await tester.pumpAndSettle();
    await _scrollToGames(tester);

    expect(find.text('Star Wars'), findsOneWidget);
    expect(find.text('Nested Build Game'), findsOneWidget);

    // The bundled sample catalogue must not leak in alongside live data.
    expect(find.text('Mystic Ruin'), findsNothing);
  });

  testWidgets('an empty catalogue says so instead of showing samples', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(_repositoryReturning({'data': []})));
    await tester.pumpAndSettle();
    await _scrollToGames(tester);

    expect(find.textContaining('No published games yet'), findsOneWidget);
    expect(find.text('Mystic Ruin'), findsNothing);
  });

  testWidgets('an unreachable backend falls back and says it did', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(_repositoryReturning({'message': 'down'}, status: 503)),
    );
    await tester.pumpAndSettle();
    await _scrollToGames(tester);

    // Stale sample data must never masquerade as the live catalogue.
    expect(find.textContaining('server could not be reached'), findsOneWidget);
    expect(find.text('Mystic Ruin'), findsOneWidget);
  });
}
