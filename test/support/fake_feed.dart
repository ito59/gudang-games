import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A stand-in for the feed API, holding just enough state that likes, posts
/// and comments behave the way the real backend does across calls.
class FakeFeedServer {
  FakeFeedServer({this.failFeed = false, this.failLike = false});

  /// Makes `GET /feed` fail, to exercise the error path.
  bool failFeed;

  /// Makes liking fail after the optimistic update has been applied.
  bool failLike;

  /// Reports the app filed, so a test can prove what reached the server.
  final List<Map<String, dynamic>> reports = [];

  /// Members the signed-in one has blocked. The real backend hides their
  /// posts and takes them out of the strip; so does this.
  final Set<int> blocked = {};

  /// Fixed relative to now, so "2h" stays "2h" and goldens do not drift with
  /// the wall clock the way a hard-coded date would.
  static final _published = DateTime.now()
      .toUtc()
      .subtract(const Duration(hours: 2))
      .toIso8601String();

  final List<Map<String, dynamic>> posts = [
    _post(
      id: '1',
      authorId: 2,
      author: 'Dita Prameswari',
      handle: 'ditaprams',
      body: 'Cleared the Mystic Ruin raid on the first try.',
      kind: 'clip',
      likes: 248,
      comments: 12,
    ),
    _post(
      id: '2',
      authorId: 3,
      author: 'Bagas Wirawan',
      handle: 'bagaswir',
      body: 'Looking for two more for tonight.',
      kind: 'squad',
      likes: 31,
      comments: 4,
    ),
  ];

  /// An announcement from the team, as the dashboard writes them.
  void seedNews() {
    posts.insert(
      0,
      _post(
        id: '9',
        authorId: 1,
        author: 'Rey Anandra',
        handle: 'neonrey',
        kind: 'news',
        title: 'Season 2 lands next week',
        body: 'Ranked resets on Monday.\n\nNew maps come with it.',
        likes: 12,
        comments: 3,
      ),
    );
  }

  final Map<String, List<Map<String, dynamic>>> comments = {
    '1': [
      {
        'id': '11',
        'body': 'That last hit was clean.',
        'created_at': _published,
        'author': {'name': 'Bagas Wirawan', 'handle': 'bagaswir', 'accent': '#14D1FF'},
      },
    ],
  };

  /// Members, keyed by id, as `/members` and `/members/{id}` answer them.
  /// The same six the design was drawn around, so the goldens still show a
  /// full strip. `friendship` is told from the signed-in member's side,
  /// exactly as the backend tells it.
  final Map<int, Map<String, dynamic>> members = {
    1: _member(
      id: 1,
      name: 'Rey Anandra',
      handle: 'neonrey',
      accent: '#D2BBFF',
      playing: 'Neon Guardian',
      avatar: 'assets/images/avatar.jpg',
      bio: 'Night-shift raider. Chasing platinum trophies and clean apex lines.',
      stats: (128, 1472, 96),
      friendship: 'self',
    ),
    2: _member(
      id: 2,
      name: 'Dita Prameswari',
      handle: 'ditaprams',
      accent: '#14D1FF',
      playing: 'Mystic Ruin',
      bio: 'Support main. If you are still standing, you are welcome.',
      stats: (74, 980, 61),
    ),
    3: _member(
      id: 3,
      name: 'Bagas Wirawan',
      handle: 'bagaswir',
      accent: '#FFB2BA',
      playing: 'Quantum Rush',
      bio: 'Time-trial grinder. Tuning setups until the lap times stop hurting.',
      stats: (52, 1310, 44),
    ),
    4: _member(
      id: 4,
      name: 'Salsa Nurhaliza',
      handle: 'salsanh',
      accent: '#4ADE80',
      playing: 'Nebula Conflict',
      bio: 'Strategy nerd. I read patch notes for fun so you do not have to.',
      stats: (96, 720, 88),
    ),
    5: _member(
      id: 5,
      name: 'Ilham Pratama',
      handle: 'ilhamp',
      accent: '#FFC46B',
      playing: 'Neon Guardian',
      bio: 'Clip hunter. Every match is a highlight reel waiting to happen.',
      stats: (41, 505, 33),
    ),
    6: _member(
      id: 6,
      name: 'Kirana Ayu',
      handle: 'kiranaayu',
      accent: '#7C3AED',
      bio: 'Taking a break from ranked. Back for the next season.',
      stats: (63, 1104, 52),
    ),
  };

  static Map<String, dynamic> _member({
    required int id,
    required String name,
    required String handle,
    required String accent,
    required String bio,
    required (int, int, int) stats,
    String? playing,
    String? avatar,
    String friendship = 'none',
  }) => {
    'id': id,
    'name': name,
    'handle': handle,
    'bio': bio,
    'avatar': avatar,
    'accent': accent,
    'playing': playing,
    'is_online': playing != null,
    'games_owned': stats.$1,
    'hours_played': stats.$2,
    'achievements': stats.$3,
    'friendship': friendship,
  };

  /// Post ids the member has liked. The real backend answers `liked_by_me`
  /// per viewer, so the feed only reports these when the request is signed.
  final Set<String> likedByMe = {};

  /// Requests the client made, so tests can assert what reached the server.
  final List<String> calls = [];

  static Map<String, dynamic> _post({
    required String id,
    required int authorId,
    required String author,
    required String handle,
    required String body,
    required String kind,
    required int likes,
    required int comments,
    String? title,
  }) => {
    'id': id,
    'title': title,
    'body': body,
    'kind': kind,
    'image': null,
    'game_tag': null,
    'likes': likes,
    'comments': comments,
    'liked_by_me': false,
    'published_at': _published,
    'author': {
      'id': authorId,
      'name': author,
      'handle': handle,
      'accent': '#7C3AED',
    },
  };

  http.Client get client => MockClient((request) async {
    final path = request.url.path;
    calls.add('${request.method} $path');

    if (path.endsWith('/login')) {
      return _json({
        'token': 'test-token',
        'user': {'id': 1, 'name': 'You', 'handle': 'you'},
      });
    }

    if (path.endsWith('/feed') && request.method == 'GET') {
      if (failFeed) return _json({'message': 'nope'}, 500);

      final signed = request.headers.containsKey('Authorization');
      final author = request.url.queryParameters['user'];
      return _json({
        'data': [
          for (final post in posts)
            if ((author == null || '${post['author']['id']}' == author) &&
                !blocked.contains(post['author']['id']))
              {
                ...post,
                'liked_by_me': signed && likedByMe.contains(post['id']),
              },
        ],
      });
    }

    if (path.endsWith('/feed') && request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final created = _post(
        id: '${posts.length + 1}',
        authorId: 1,
        author: 'You',
        handle: 'you',
        body: body['body'] as String,
        kind: body['kind'] as String,
        likes: 0,
        comments: 0,
      );
      posts.insert(0, created);
      return _json({'data': created}, 201);
    }

    if (path.endsWith('/report-reasons')) {
      return _json({
        'data': [
          {'value': 'spam', 'label': 'Spam or scam'},
          {'value': 'harassment', 'label': 'Harassment or bullying'},
          {'value': 'other', 'label': 'Something else'},
        ],
      });
    }

    if (path.endsWith('/reports') && request.method == 'POST') {
      reports.add(jsonDecode(request.body) as Map<String, dynamic>);
      return _json({
        'data': {'id': reports.length, 'status': 'pending'},
      }, 201);
    }

    if (path.endsWith('/me/blocks')) {
      return _json({
        'data': blocked.map((id) => members[id]).nonNulls.toList(),
      });
    }

    final block = RegExp(r'/members/(\d+)/block$').firstMatch(path);
    if (block != null) {
      final id = int.parse(block.group(1)!);
      final now = request.method == 'POST';
      now ? blocked.add(id) : blocked.remove(id);
      members[id]?['blocked'] = now;
      return _json({'blocked': now});
    }

    if (path.endsWith('/members') && request.method == 'GET') {
      return _json({
        'data': members.values
            .where((m) => !blocked.contains(m['id']))
            .toList(),
      });
    }

    if (path.endsWith('/friend-requests')) {
      return _json({
        'data': members.values
            .where((m) => m['friendship'] == 'pending')
            .toList(),
      });
    }

    final friend = RegExp(r'/members/(\d+)/friend(/accept)?$').firstMatch(path);
    if (friend != null) {
      final member = members[int.parse(friend.group(1)!)]!;
      member['friendship'] = switch ((request.method, friend.group(2))) {
        ('DELETE', _) => 'none',
        (_, '/accept') => 'friends',
        // Asking somebody who already asked you accepts, as the backend does.
        _ => member['friendship'] == 'pending' ? 'friends' : 'requested',
      };
      return _json({'friendship': member['friendship']});
    }

    final member = RegExp(r'/members/(\d+)$').firstMatch(path);
    if (member != null) {
      final found = members[int.parse(member.group(1)!)];
      return found == null
          ? _json({'message': 'not found'}, 404)
          : _json({'data': found});
    }

    final like = RegExp(r'/feed/([^/]+)/like$').firstMatch(path);
    if (like != null) {
      if (failLike) return _json({'message': 'nope'}, 500);

      final post = posts.firstWhere((p) => p['id'] == like.group(1));
      final liked = request.method == 'POST';
      liked ? likedByMe.add(post['id'] as String) : likedByMe.remove(post['id']);
      post['likes'] = (post['likes'] as int) + (liked ? 1 : -1);
      return _json({'likes': post['likes'], 'liked': liked});
    }

    final thread = RegExp(r'/feed/([^/]+)/comments$').firstMatch(path);
    if (thread != null) {
      final id = thread.group(1)!;
      if (request.method == 'GET') {
        return _json({'data': comments[id] ?? const []});
      }

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final created = {
        'id': 'c${comments.values.fold(0, (n, list) => n + list.length) + 1}',
        'body': body['body'],
        'created_at': _published,
        'author': {'name': 'You', 'handle': 'you', 'accent': '#7C3AED'},
      };
      (comments[id] ??= []).add(created);

      final post = posts.firstWhere((p) => p['id'] == id);
      post['comments'] = (post['comments'] as int) + 1;
      return _json({'data': created}, 201);
    }

    return _json({'message': 'not found'}, 404);
  });

  static http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}
