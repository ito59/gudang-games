import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A stand-in for `/me/notifications` and `/me/devices`.
class FakeNotificationServer {
  FakeNotificationServer({
    this.chat = true,
    this.news = true,
    this.pushAvailable = false,
  });

  bool chat;
  bool news;
  bool pushAvailable;

  /// Makes saving fail, the way an unreachable server does.
  bool failSaves = false;

  final List<String> calls = [];
  final List<Map<String, dynamic>> devices = [];

  Map<String, Object?> get _payload => {
    'chat': chat,
    'news': news,
    'push_available': pushAvailable,
    'news_topic': 'news',
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

    if (path.endsWith('/me/devices')) {
      devices.add({
        'method': request.method,
        ...jsonDecode(request.body) as Map<String, dynamic>,
      });
      return _json({'data': _payload});
    }

    if (path.endsWith('/me/notifications')) {
      if (request.method == 'PATCH') {
        if (failSaves) return _json({'message': 'nope'}, 500);

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body.containsKey('chat')) chat = body['chat'] as bool;
        if (body.containsKey('news')) news = body['news'] as bool;
      }

      return _json({'data': _payload});
    }

    return _json({'message': 'not found'}, 404);
  });

  static http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}
