import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import '../models/community_post.dart';
import '../models/conversation.dart';
import '../state/auth_scope.dart';
import 'api_config.dart';

/// The one-to-one threads endpoint.
///
/// Every call needs a token: a thread belongs to the two people in it, and
/// the backend answers a stranger with a 403 rather than an empty list.
class ChatRepository {
  ChatRepository({required this.auth, http.Client? client})
    : _client = client ?? http.Client();

  final Auth auth;
  final http.Client _client;

  /// The viewer's threads, most recently spoken in first. Empty when the
  /// server could not be reached; the screen says so rather than inventing
  /// conversations.
  Future<List<Conversation>> conversations() async {
    try {
      final response = await _client
          .get(ApiConfig.endpoint('conversations'), headers: auth.headers)
          .timeout(ApiConfig.timeout);

      if (auth.wasRejected(response)) return const [];
      if (response.statusCode != 200) return const [];

      final data = _dataOf(response.body);
      if (data is! List) return const [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(conversationFrom)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Opens the thread with a member, making it if this is the first message.
  /// Null when the call failed.
  Future<Conversation?> openWith(int memberId) async {
    try {
      final response = await _client
          .post(
            ApiConfig.endpoint('conversations'),
            headers: {...auth.headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': memberId}),
          )
          .timeout(ApiConfig.timeout);

      if (auth.wasRejected(response)) return null;
      if (response.statusCode != 200 && response.statusCode != 201) return null;

      final data = _dataOf(response.body);
      return data is Map<String, dynamic> ? conversationFrom(data) : null;
    } catch (_) {
      return null;
    }
  }

  /// A thread's messages, oldest first.
  Future<List<ChatMessage>> messages(String conversationId) async {
    try {
      final response = await _client
          .get(
            ApiConfig.endpoint('conversations/$conversationId/messages'),
            headers: auth.headers,
          )
          .timeout(ApiConfig.timeout);

      if (auth.wasRejected(response)) return const [];
      if (response.statusCode != 200) return const [];

      final data = _dataOf(response.body);
      if (data is! List) return const [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(messageFrom)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Sends a message.
  ///
  /// Returns the message as the server stored it, or the reason it refused —
  /// exactly one of the two. The reason is passed through rather than
  /// flattened to "that did not send", because the moderation filter answers
  /// here and a sender who is not told what was wrong will simply send it
  /// again.
  ///
  /// [socketId] is this client's live connection. Passing it is what stops
  /// the sender's own message arriving twice — once optimistically and once
  /// off the socket.
  Future<({ChatMessage? message, String? error})> send(
    String conversationId,
    String body, {
    String? socketId,
  }) async {
    final headers = {...auth.headers, 'Content-Type': 'application/json'};
    if (socketId != null) headers['X-Socket-ID'] = socketId;

    try {
      final response = await _client
          .post(
            ApiConfig.endpoint('conversations/$conversationId/messages'),
            headers: headers,
            body: jsonEncode({'body': body.trim()}),
          )
          .timeout(ApiConfig.timeout);

      if (auth.wasRejected(response)) {
        return (message: null, error: 'Sign in to send that.');
      }

      if (response.statusCode != 201) {
        return (message: null, error: _refusalOf(response));
      }

      final data = _dataOf(response.body);

      return data is Map<String, dynamic>
          ? (message: messageFrom(data), error: null)
          : (message: null, error: 'That message did not send.');
    } catch (_) {
      return (message: null, error: 'That message did not send.');
    }
  }

  /// What to show the sender when the server would not take the message.
  ///
  /// A 422 carries a reason worth reading — too long, or refused by the
  /// filter. A 403 is a block, which is answered without saying so: telling
  /// somebody they have been blocked is the one thing blocking must not do.
  static String _refusalOf(http.Response response) {
    const generic = 'That message did not send.';

    if (response.statusCode != 422) return generic;

    try {
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return generic;

      final errors = body['errors'];
      if (errors is Map && errors['body'] is List && errors['body'].isNotEmpty) {
        return '${errors['body'].first}';
      }

      final message = body['message'];
      return message is String && message.isNotEmpty ? message : generic;
    } catch (_) {
      return generic;
    }
  }

  /// Everything up to now has been seen. Failure is silent: an unread badge
  /// that clears on the next load is not worth interrupting anybody for.
  Future<void> markRead(String conversationId) async {
    try {
      await _client
          .post(
            ApiConfig.endpoint('conversations/$conversationId/read'),
            headers: auth.headers,
          )
          .timeout(ApiConfig.timeout);
    } catch (_) {
      // Nothing to do.
    }
  }

  /// Builds a thread from the `/conversations` payload. The message list
  /// arrives separately, so a freshly listed thread holds only its last line.
  static Conversation conversationFrom(Map<String, dynamic> json) {
    final with_ = json['with'];
    final last = json['last_message'];

    return Conversation(
      id: '${json['id']}',
      memberId: with_ is Map ? (with_['id'] as num?)?.toInt() ?? 0 : 0,
      name: with_ is Map ? (with_['name'] as String?) ?? '' : '',
      handle: with_ is Map ? (with_['handle'] as String?) ?? '' : '',
      accent: CommunityPost.colorFrom(
        with_ is Map ? with_['accent'] as String? : null,
      ),
      avatar: with_ is Map ? with_['avatar'] as String? : null,
      playing: with_ is Map ? with_['playing'] as String? : null,
      isOnline: with_ is Map && with_['is_online'] == true,
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      theirLastReadId: (json['their_last_read_id'] as num?)?.toInt(),
      messages: last is Map<String, dynamic>
          ? [
              ChatMessage(
                // The list only says what was said last, not which row it
                // was; opening the thread replaces this with the real one.
                id: 'last-${json['id']}',
                text: (last['body'] as String?) ?? '',
                sentAt:
                    DateTime.tryParse((last['created_at'] as String?) ?? '') ??
                    DateTime.now(),
                isMine: last['mine'] == true,
              ),
            ]
          : const [],
    );
  }

  static ChatMessage messageFrom(Map<String, dynamic> json) {
    final author = json['author'];

    return ChatMessage(
      id: '${json['id']}',
      text: (json['body'] as String?) ?? '',
      sentAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
      isMine: false,
      authorId: author is Map ? (author['id'] as num?)?.toInt() ?? 0 : 0,
    );
  }

  static Object? _dataOf(String body) {
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded['data'] : null;
  }
}
