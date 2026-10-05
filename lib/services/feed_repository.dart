import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/community_post.dart';
import '../state/auth_scope.dart';
import 'api_config.dart';

/// A comment on a post.
class PostComment {
  const PostComment({
    required this.id,
    required this.body,
    required this.authorName,
    required this.authorHandle,
    required this.accent,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final author = json['author'];

    return PostComment(
      id: '${json['id']}',
      body: (json['body'] as String?) ?? '',
      authorName: author is Map ? (author['name'] as String?) ?? '' : '',
      authorHandle: author is Map ? (author['handle'] as String?) ?? '' : '',
      accent: author is Map ? author['accent'] as String? : null,
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String body;
  final String authorName;
  final String authorHandle;
  final String? accent;
  final DateTime createdAt;
}

/// What a feed request produced.
class FeedResult {
  const FeedResult({required this.posts, required this.fromBackend, this.error});

  final List<CommunityPost> posts;
  final bool fromBackend;
  final String? error;
}

class FeedRepository {
  FeedRepository({required this.auth, http.Client? client})
    : _client = client ?? http.Client();

  final Auth auth;
  final http.Client _client;

  /// The feed, or one member's posts when [authorId] is given.
  Future<FeedResult> fetchFeed({String? kind, int? authorId}) async {
    final query = <String, String>{};
    if (kind != null) query['kind'] = kind;
    if (authorId != null) query['user'] = '$authorId';

    try {
      final response = await _client
          .get(
            ApiConfig.endpoint('feed', query),
            // Sent when signed in so `liked_by_me` reflects this member.
            headers: auth.headers,
          )
          .timeout(ApiConfig.timeout);

      if (auth.wasRejected(response)) {
        return const FeedResult(
          posts: [],
          fromBackend: false,
          error: 'Please sign in again.',
        );
      }

      if (response.statusCode != 200) {
        return FeedResult(
          posts: const [],
          fromBackend: false,
          error: 'Feed unavailable (${response.statusCode}).',
        );
      }

      final body = jsonDecode(response.body);
      final data = (body is Map<String, dynamic>) ? body['data'] : null;
      if (data is! List) {
        return const FeedResult(
          posts: [],
          fromBackend: false,
          error: 'Unexpected response.',
        );
      }

      return FeedResult(
        posts: data
            .whereType<Map<String, dynamic>>()
            .map(CommunityPost.fromJson)
            .toList(),
        fromBackend: true,
      );
    } catch (error) {
      return FeedResult(
        posts: const [],
        fromBackend: false,
        error: 'Could not reach the server.',
      );
    }
  }

  /// Returns the created post, or null with a message on failure.
  Future<(CommunityPost?, String?)> createPost({
    required String body,
    required PostKind kind,
  }) async {
    try {
      final response = await _client
          .post(
            ApiConfig.endpoint('feed'),
            headers: {...auth.headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'body': body.trim(), 'kind': kind.name}),
          )
          .timeout(ApiConfig.timeout);

      auth.wasRejected(response);

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (data is Map<String, dynamic>) {
          return (CommunityPost.fromJson(data), null);
        }
      }

      return (null, _messageFrom(response));
    } catch (_) {
      return (null, 'Could not reach the server.');
    }
  }

  /// Returns the new like count, or null when the call failed.
  Future<int?> setLiked(String postId, bool liked) async {
    try {
      final uri = ApiConfig.endpoint('feed/$postId/like');
      final response = await (liked
              ? _client.post(uri, headers: auth.headers)
              : _client.delete(uri, headers: auth.headers))
          .timeout(ApiConfig.timeout);

      if (auth.wasRejected(response)) return null;
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      return body is Map<String, dynamic>
          ? (body['likes'] as num?)?.toInt()
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<PostComment>> fetchComments(String postId) async {
    try {
      final response = await _client
          .get(ApiConfig.endpoint('feed/$postId/comments'), headers: auth.headers)
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) return const [];

      final body = jsonDecode(response.body);
      final data = (body is Map<String, dynamic>) ? body['data'] : null;
      if (data is! List) return const [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(PostComment.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<(PostComment?, String?)> addComment(String postId, String body) async {
    try {
      final response = await _client
          .post(
            ApiConfig.endpoint('feed/$postId/comments'),
            headers: {...auth.headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'body': body.trim()}),
          )
          .timeout(ApiConfig.timeout);

      auth.wasRejected(response);

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (data is Map<String, dynamic>) {
          return (PostComment.fromJson(data), null);
        }
      }

      return (null, _messageFrom(response));
    } catch (_) {
      return (null, 'Could not reach the server.');
    }
  }

  /// Surfaces the server's own wording rather than a generic failure.
  String _messageFrom(http.Response response) {
    if (response.statusCode == 401) return 'Please sign in first.';

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return '${first.first}';
        }
        if (body['message'] is String) return body['message'] as String;
      }
    } catch (_) {}

    return 'That did not work (${response.statusCode}).';
  }
}
