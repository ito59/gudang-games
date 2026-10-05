import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game.dart';

/// One game the player has opened, and how often.
class PlayedGame {
  const PlayedGame({
    required this.game,
    required this.plays,
    required this.lastPlayed,
  });

  factory PlayedGame.fromJson(Map<String, dynamic> json) {
    return PlayedGame(
      // A snapshot, so history still renders for a game the backend has
      // since unpublished.
      game: Game.fromJson(json['game'] as Map<String, dynamic>),
      plays: (json['plays'] as num?)?.toInt() ?? 1,
      lastPlayed: DateTime.fromMillisecondsSinceEpoch(
        (json['last_played'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  final Game game;
  final int plays;
  final DateTime lastPlayed;

  Map<String, dynamic> toJson() => {
    'game': {
      'title': game.title,
      'slug': game.slug,
      'category': game.category,
      'rating': game.rating,
      'description': game.description,
      'plays_count': game.playsCount,
      'image': game.image,
      'play_url': game.playUrl,
      'trailer_url': game.trailerUrl,
      'source_type': game.isHosted ? 'zip' : 'url',
    },
    'plays': plays,
    'last_played': lastPlayed.millisecondsSinceEpoch,
  };
}

/// What this person has played, kept on the device.
///
/// The app has no sign-in yet, so "this user" means this installation. When
/// accounts arrive, move the counters behind the API and keep this as a cache.
class PlayHistory extends ChangeNotifier {
  PlayHistory({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'play_history_v1';

  final SharedPreferencesAsync _preferences;

  var _entries = <String, PlayedGame>{};
  var _loaded = false;

  bool get isLoaded => _loaded;

  /// Most played first; ties broken by whichever was played most recently.
  List<PlayedGame> get games {
    final list = _entries.values.toList()
      ..sort((a, b) {
        final byPlays = b.plays.compareTo(a.plays);
        return byPlays != 0 ? byPlays : b.lastPlayed.compareTo(a.lastPlayed);
      });
    return List.unmodifiable(list);
  }

  Future<void> load() async {
    try {
      final raw = await _preferences.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _entries = {
            for (final item in decoded.whereType<Map<String, dynamic>>())
              if (PlayedGame.fromJson(item).game.slug.isNotEmpty)
                PlayedGame.fromJson(item).game.slug: PlayedGame.fromJson(item),
          };
        }
      }
    } catch (_) {
      // Corrupt or unreadable history is not worth failing the app over.
      _entries = {};
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> record(Game game) async {
    if (game.slug.isEmpty) return;

    final existing = _entries[game.slug];
    _entries = {
      ..._entries,
      game.slug: PlayedGame(
        // Refreshed each play, so covers and titles stay current.
        game: game,
        plays: (existing?.plays ?? 0) + 1,
        lastPlayed: DateTime.now(),
      ),
    };

    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _entries = {};
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _preferences.setString(
        storageKey,
        jsonEncode(_entries.values.map((entry) => entry.toJson()).toList()),
      );
    } catch (_) {
      // Losing the write is better than crashing after a game was played.
    }
  }
}

class PlayHistoryScope extends InheritedNotifier<PlayHistory> {
  const PlayHistoryScope({
    super.key,
    required PlayHistory super.notifier,
    required super.child,
  });

  static PlayHistory of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PlayHistoryScope>();
    assert(scope != null, 'No PlayHistoryScope found in context');
    return scope!.notifier!;
  }
}
