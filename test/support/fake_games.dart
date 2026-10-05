import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bandar_games/data/mock_data.dart';
import 'package:bandar_games/models/featured_event.dart';
import 'package:bandar_games/models/game.dart';
import 'package:bandar_games/models/game_category.dart';
import 'package:bandar_games/services/game_repository.dart';

/// A repository that answers from memory.
///
/// Tests must never reach the network: it makes them slow, flaky, and
/// dependent on whether a dev server happens to be running.
GameRepository fakeGameRepository({
  List<Game>? games,
  List<FeaturedEvent>? slides,
  List<GameCategory>? categories,
}) {
  final categoryPayload = categoriesPayload(categories ?? const []);
  final featured = featuredPayload(slides ?? const []);
  final payload = gamesPayload(games ?? popularGames);

  return GameRepository(
    client: MockClient(
      (request) async => http.Response(
        jsonEncode(switch (request.url.path) {
          final path when path.endsWith('/featured') => featured,
          final path when path.endsWith('/categories') => categoryPayload,
          _ => payload,
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    ),
  );
}

/// A catalogue whose answers a test can change between requests, so a
/// pull-to-refresh has something new to find.
class FakeCatalogueServer {
  FakeCatalogueServer({
    List<Game>? games,
    List<FeaturedEvent>? slides,
    List<GameCategory>? categories,
  }) : games = games ?? popularGames,
       slides = slides ?? const [],
       categories = categories ?? const [];

  List<Game> games;
  List<FeaturedEvent> slides;
  List<GameCategory> categories;

  /// Makes every request fail, the way an unreachable server does.
  bool offline = false;

  /// How many times each list was asked for, so a test can prove a refresh
  /// actually went back to the server.
  final List<String> calls = [];

  GameRepository get repository => GameRepository(
    client: MockClient((request) async {
      final path = request.url.path;
      calls.add(path);

      if (offline) {
        return http.Response('{"message":"nope"}', 500,
            headers: {'content-type': 'application/json'});
      }

      // Built per request, not once: the point is that the answer can change.
      return http.Response(
        jsonEncode(switch (path) {
          final p when p.endsWith('/featured') => featuredPayload(slides),
          final p when p.endsWith('/categories') => categoriesPayload(categories),
          _ => gamesPayload(games),
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );

  int callsTo(String suffix) =>
      calls.where((path) => path.endsWith(suffix)).length;
}

/// @nodoc
Map<String, Object?> categoriesPayload(List<GameCategory> categories) {
  return {
    'data': [
      for (final category in categories)
        {'label': category.label, 'slug': category.slug, 'icon': 'swords'},
    ],
  };
}

/// @nodoc
Map<String, Object?> featuredPayload(List<FeaturedEvent> slides) {
  return {
    'data': [
      for (final slide in slides)
        {
          'id': 'slide',
          'title': slide.title,
          'description': slide.description,
          'season': slide.season,
          'is_live': slide.isLive,
          'image': slide.image,
          'game': slide.game == null
              ? null
              : {
                  'title': slide.game!.title,
                  'slug': slide.game!.slug,
                  'category': slide.game!.category,
                  'rating': slide.game!.rating,
                  'description': slide.game!.description,
                  'plays_count': slide.game!.playsCount,
                  'image': slide.game!.image,
                  'play_url': slide.game!.playUrl,
                  'trailer_url': slide.game!.trailerUrl,
                  'source_type': slide.game!.isHosted ? 'zip' : 'url',
                },
        },
    ],
  };
}

/// @nodoc
Map<String, Object?> gamesPayload(List<Game> games) {
  return {
    'data': [
      for (final game in games)
        {
          'title': game.title,
          'slug': game.slug,
          'description': game.description,
          'plays_count': game.playsCount,
          'category': game.category,
          'category_slug': game.categorySlug,
          'rating': game.rating,
          'image': game.image,
          'source_type': game.isHosted ? 'zip' : 'url',
          'play_url': game.playUrl,
          'trailer_url': game.trailerUrl,
        },
    ],
  };
}
