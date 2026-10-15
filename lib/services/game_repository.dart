import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/mock_data.dart';
import '../models/game.dart';
import '../models/game_category.dart';
import 'api_config.dart';

/// Result of asking the backend for the catalogue.
///
/// The screen needs to know *why* it is showing what it shows, so an
/// unreachable backend is not silently indistinguishable from an empty one.
class GamesResult {
  const GamesResult({required this.games, required this.fromBackend, this.error});

  final List<Game> games;

  /// False when the bundled sample catalogue is being shown instead.
  final bool fromBackend;
  final String? error;
}

class GameRepository {
  GameRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Published games from the backend.
  ///
  /// Falls back to the bundled catalogue when the backend cannot be reached,
  /// so the app still renders on a phone with no route to the dev machine.
  Future<GamesResult> fetchGames() async {
    try {
      final response = await _client
          .get(ApiConfig.endpoint('games'))
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) {
        return _fallback('Backend returned ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      final data = (body is Map<String, dynamic>) ? body['data'] : null;

      if (data is! List) {
        return _fallback('Unexpected response shape');
      }

      final games = data
          .whereType<Map<String, dynamic>>()
          .map(Game.fromJson)
          .toList();

      return GamesResult(games: games, fromBackend: true);
    } catch (error) {
      return _fallback(error.toString());
    }
  }

  /// Categories for the browse strip.
  ///
  /// Falls back to the bundled set so the strip is never empty, and drops any
  /// category with no slug — one that cannot be matched to a game would be a
  /// filter that always comes back blank.
  Future<List<GameCategory>> fetchCategories() async {
    try {
      final response = await _client
          .get(ApiConfig.endpoint('categories'))
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) return gameCategories;

      final body = jsonDecode(response.body);
      final data = (body is Map<String, dynamic>) ? body['data'] : null;
      if (data is! List) return gameCategories;

      final categories = data
          .whereType<Map<String, dynamic>>()
          .map(GameCategory.fromJson)
          .where((category) => category.slug.isNotEmpty)
          .toList();

      return categories.isEmpty ? gameCategories : categories;
    } catch (_) {
      return gameCategories;
    }
  }

  /// Carousel slides: the games an admin flagged as featured.
  ///
  /// Each slide in the payload carries its game. Slides without one are
  /// skipped — an older server may still send hand-written campaign slides,
  /// which have nothing to open. Falls back to the bundled slides so the home
  /// screen is never blank.
  Future<List<Game>> fetchFeatured() async {
    try {
      final response = await _client
          .get(ApiConfig.endpoint('featured'))
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) return featuredGames;

      final body = jsonDecode(response.body);
      final data = (body is Map<String, dynamic>) ? body['data'] : null;
      if (data is! List) return featuredGames;

      final games = data
          .whereType<Map<String, dynamic>>()
          .map((slide) => slide['game'])
          .whereType<Map<String, dynamic>>()
          .map(Game.fromJson)
          .toList();

      // An empty carousel would leave a hole where the hero belongs.
      return games.isEmpty ? featuredGames : games;
    } catch (_) {
      return featuredGames;
    }
  }

  /// Tells the backend a game was opened. Fire-and-forget: a failed count
  /// must never stop somebody playing.
  Future<void> recordPlay(String slug) async {
    if (slug.isEmpty) return;

    try {
      await _client
          .post(ApiConfig.endpoint('games/$slug/play'))
          .timeout(ApiConfig.timeout);
    } catch (_) {
      // Popularity is not worth interrupting a player for.
    }
  }

  GamesResult _fallback(String error) =>
      GamesResult(games: popularGames, fromBackend: false, error: error);
}
