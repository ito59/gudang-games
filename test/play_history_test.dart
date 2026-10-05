import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:bandar_games/models/game.dart';
import 'package:bandar_games/state/play_history.dart';

Game _game(String slug) => Game(
  title: slug,
  slug: slug,
  category: 'ACTION',
  rating: 4,
  image: '',
);

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty());

  test('orders by play count, most played first', () async {
    final history = PlayHistory();
    await history.load();

    await history.record(_game('once'));
    await history.record(_game('thrice'));
    await history.record(_game('thrice'));
    await history.record(_game('thrice'));
    await history.record(_game('twice'));
    await history.record(_game('twice'));

    expect(
      history.games.map((e) => e.game.slug),
      ['thrice', 'twice', 'once'],
    );
    expect(history.games.first.plays, 3);
  });

  test('a tie is broken by whichever was played more recently', () async {
    final history = PlayHistory();
    await history.load();

    await history.record(_game('older'));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await history.record(_game('newer'));

    expect(history.games.map((e) => e.game.slug), ['newer', 'older']);
  });

  test('replaying a game increments rather than duplicating', () async {
    final history = PlayHistory();
    await history.load();

    await history.record(_game('same'));
    await history.record(_game('same'));

    expect(history.games, hasLength(1));
    expect(history.games.single.plays, 2);
  });

  test('history survives a restart', () async {
    final first = PlayHistory();
    await first.load();
    await first.record(_game('kept'));
    await first.record(_game('kept'));

    final second = PlayHistory();
    await second.load();

    expect(second.games.single.game.slug, 'kept');
    expect(second.games.single.plays, 2);
  });

  test('a game without a slug is ignored', () async {
    final history = PlayHistory();
    await history.load();

    await history.record(
      const Game(title: 'No slug', category: 'RPG', rating: 3, image: ''),
    );

    expect(history.games, isEmpty);
  });

  test('corrupt storage does not break the app', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
      PlayHistory.storageKey: 'not json at all',
    });

    final history = PlayHistory();
    await history.load();

    expect(history.isLoaded, isTrue);
    expect(history.games, isEmpty);
  });
}
