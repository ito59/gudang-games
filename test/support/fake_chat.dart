import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bandar_games/services/realtime.dart';

/// A stand-in for the chat API, holding threads and messages between calls so
/// a send is visible to the next read.
class FakeChatServer {
  FakeChatServer({this.viewerId = 1, this.failSends = false});

  /// Who the token belongs to, so `mine` and the unread count mean something.
  final int viewerId;

  /// Makes sending fail after the message is on screen.
  bool failSends;

  /// Makes the moderation filter refuse every send, the way the real one
  /// answers: 422 with the reason under `body`.
  String? refuseSendsWith;

  /// Refuses every token, the way a server does when the token was revoked,
  /// wiped with the database, or issued by a different backend.
  bool rejectTokens = false;

  final List<Map<String, dynamic>> conversations = [];
  final Map<String, List<Map<String, dynamic>>> messages = {};

  /// Requests the client made, so tests can assert what reached the server.
  final List<String> calls = [];

  var _nextConversation = 1;
  var _nextMessage = 1;

  /// A thread with somebody, as `/conversations` answers it.
  String seedThread({
    required int memberId,
    required String name,
    String handle = 'them',
    String accent = '#14D1FF',
    int unread = 0,
  }) {
    final id = '${_nextConversation++}';
    conversations.add({
      'id': id,
      'with': {
        'id': memberId,
        'name': name,
        'handle': handle,
        'accent': accent,
        'avatar': null,
        'playing': 'Neon Guardian',
        'is_online': true,
      },
      'last_message': null,
      'unread': unread,
      'their_last_read_id': null,
      'last_message_at': null,
    });
    messages[id] = [];
    return id;
  }

  /// A message already in a thread, as if it were sent before the app looked.
  void seedMessage(
    String conversationId,
    String body, {
    required int authorId,
    DateTime? at,
  }) {
    final message = _message(conversationId, body, authorId);
    if (at != null) message['created_at'] = at.toUtc().toIso8601String();
    messages[conversationId]!.add(message);
    _conversation(conversationId)['last_message'] = {
      'body': body,
      'mine': authorId == viewerId,
      'created_at': message['created_at'],
    };
  }

  Map<String, dynamic> _message(String conversationId, String body, int authorId) => {
    'id': '${_nextMessage++}',
    'conversation_id': conversationId,
    'body': body,
    'author': {
      'id': authorId,
      'name': authorId == viewerId ? 'You' : 'Them',
      'handle': authorId == viewerId ? 'you' : 'them',
      'accent': '#7C3AED',
      'avatar': null,
    },
    'created_at': DateTime.now().toUtc().toIso8601String(),
  };

  Map<String, dynamic> _conversation(String id) =>
      conversations.firstWhere((c) => c['id'] == id);

  http.Client get client => MockClient((request) async {
    final path = request.url.path;
    calls.add('${request.method} $path');

    if (rejectTokens && !path.endsWith('/login')) {
      return _json({'message': 'Unauthenticated.'}, 401);
    }

    if (path.endsWith('/login')) {
      return _json({
        'token': 'test-token',
        'user': {'data': {'id': viewerId, 'name': 'You', 'handle': 'you'}},
      });
    }

    if (path.endsWith('/config')) {
      return _json({
        'google': {'enabled': false},
        'realtime': {
          'enabled': true,
          'key': 'test-key',
          'host': 'socket.test',
          'port': 8080,
          'scheme': 'ws',
        },
      });
    }

    if (path.endsWith('/broadcasting/auth')) {
      return _json({'auth': 'test-key:signature'});
    }

    if (path.endsWith('/conversations') && request.method == 'GET') {
      return _json({'data': conversations});
    }

    if (path.endsWith('/conversations') && request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final memberId = body['user_id'] as int;

      final existing = conversations
          .where((c) => (c['with'] as Map)['id'] == memberId)
          .firstOrNull;
      if (existing != null) return _json({'data': existing});

      final id = seedThread(memberId: memberId, name: 'Member $memberId');
      return _json({'data': _conversation(id)}, 201);
    }

    final thread = RegExp(r'/conversations/(\d+)/messages$').firstMatch(path);
    if (thread != null) {
      final id = thread.group(1)!;

      if (request.method == 'GET') {
        return _json({'data': messages[id] ?? const []});
      }

      if (failSends) return _json({'message': 'nope'}, 500);

      final refusal = refuseSendsWith;
      if (refusal != null) {
        return _json({
          'message': refusal,
          'errors': {
            'body': [refusal],
          },
        }, 422);
      }

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final message = _message(id, body['body'] as String, viewerId);
      (messages[id] ??= []).add(message);
      _conversation(id)['last_message'] = {
        'body': message['body'],
        'mine': true,
        'created_at': message['created_at'],
      };

      // The real backend leaves the sender out of its own broadcast.
      sentSocketIds.add(request.headers['X-Socket-ID'] ?? request.headers['x-socket-id']);

      return _json({'data': message}, 201);
    }

    if (RegExp(r'/conversations/\d+/read$').hasMatch(path)) {
      return _json({'last_read_message_id': 0});
    }

    return _json({'message': 'not found'}, 404);
  });

  /// The `X-Socket-ID` header each send carried, so a test can prove the
  /// sender asked not to be echoed its own message.
  final List<String?> sentSocketIds = [];

  static http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}

/// A [Realtime] a test drives by hand.
class FakeRealtime implements Realtime {
  final _controller = StreamController<RealtimeEvent>.broadcast();

  final List<String> subscribed = [];
  var closed = false;

  @override
  Stream<RealtimeEvent> get events => _controller.stream;

  @override
  String? socketId = 'fake.socket';

  /// Pushes a read receipt as the server would.
  void markRead(String conversationId, {required int readerId, int? upTo}) {
    _controller.add(
      RealtimeEvent(
        channel: 'private-conversation.$conversationId',
        name: 'thread.read',
        data: {
          'conversation_id': conversationId,
          'reader_id': readerId,
          'last_read_message_id': upTo,
        },
      ),
    );
  }

  /// Pushes a message as the server would.
  void deliver(String conversationId, Map<String, dynamic> message) {
    _controller.add(
      RealtimeEvent(
        channel: 'private-conversation.$conversationId',
        name: 'message.sent',
        data: {'conversation_id': conversationId, 'message': message},
      ),
    );
  }

  @override
  Future<void> subscribe(String channel) async => subscribed.add(channel);

  @override
  Future<void> unsubscribe(String channel) async => subscribed.remove(channel);

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }
}
