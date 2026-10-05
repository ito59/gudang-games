import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bandar_games/services/game_repository.dart';

http.Client _clientReturning(Object body, {int status = 200}) {
  return MockClient((request) async => http.Response(
        body is String ? body : jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      ));
}

void main() {
  test('maps the backend payload onto games', () async {
    final repository = GameRepository(
      client: _clientReturning({
        'data': [
          {
            'id': 7,
            'title': 'Star Wars',
            'category': 'Action',
            'rating': 4.5,
            'image': 'http://example.test/storage/covers/a.jpg',
            'source_type': 'zip',
            'play_url': 'http://example.test/games/star-wars/play/index.html',
          },
        ],
      }),
    );

    final result = await repository.fetchGames();

    expect(result.fromBackend, isTrue);
    expect(result.games, hasLength(1));

    final game = result.games.single;
    expect(game.title, 'Star Wars');
    // The card shows categories upper-cased.
    expect(game.category, 'ACTION');
    expect(game.rating, 4.5);
    expect(game.isHosted, isTrue);
    expect(game.imageIsRemote, isTrue);
    expect(game.playUrl, endsWith('/play/index.html'));
  });

  test('survives a game with no category, cover or source', () async {
    final repository = GameRepository(
      client: _clientReturning({
        'data': [
          {'id': 1, 'title': 'Bare Game', 'rating': 0},
        ],
      }),
    );

    final game = (await repository.fetchGames()).games.single;

    expect(game.title, 'Bare Game');
    expect(game.category, 'GAME');
    expect(game.hasImage, isFalse);
    expect(game.playUrl, isNull);
    expect(game.isHosted, isFalse);
  });

  test('an empty catalogue is reported as empty, not as a failure', () async {
    final repository = GameRepository(client: _clientReturning({'data': []}));

    final result = await repository.fetchGames();

    expect(result.fromBackend, isTrue);
    expect(result.games, isEmpty);
  });

  test('falls back to the bundled catalogue when the server errors', () async {
    final repository = GameRepository(
      client: _clientReturning({'message': 'boom'}, status: 500),
    );

    final result = await repository.fetchGames();

    expect(result.fromBackend, isFalse);
    expect(result.games, isNotEmpty);
    expect(result.error, contains('500'));
  });

  test('falls back when the server cannot be reached at all', () async {
    final repository = GameRepository(
      client: MockClient((_) async => throw const SocketishFailure()),
    );

    final result = await repository.fetchGames();

    expect(result.fromBackend, isFalse);
    expect(result.games, isNotEmpty);
  });

  test('falls back on a response that is not the expected shape', () async {
    final repository = GameRepository(client: _clientReturning('not json'));

    final result = await repository.fetchGames();

    expect(result.fromBackend, isFalse);
  });
}

/// Stands in for a network failure without depending on dart:io.
class SocketishFailure implements Exception {
  const SocketishFailure();
}
