import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/community_member.dart';
import '../state/auth_scope.dart';
import 'api_config.dart';

/// Members and the friendships between them.
///
/// Reads are public — a profile is visible signed out — but every friend call
/// needs a token, because the row it writes belongs to a member.
class MemberRepository {
  MemberRepository({required this.auth, http.Client? client})
    : _client = client ?? http.Client();

  final Auth auth;
  final http.Client _client;

  /// The "Online now" strip. Empty when the server cannot be reached, which
  /// leaves the strip out rather than showing players who are not there.
  Future<List<CommunityMember>> online() => _members(ApiConfig.endpoint('members'));

  /// Members waiting on an answer from the signed-in one.
  Future<List<CommunityMember>> friendRequests() =>
      _members(ApiConfig.endpoint('friend-requests'));

  /// One member, freshly read so the friendship state is the current one.
  /// Null when the call failed; the caller keeps what it already had.
  Future<CommunityMember?> fetch(int id) async {
    try {
      final response = await _client
          .get(ApiConfig.endpoint('members/$id'), headers: auth.headers)
          .timeout(ApiConfig.timeout);

      if (auth.wasRejected(response)) return null;
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      final data = (body is Map<String, dynamic>) ? body['data'] : null;
      return data is Map<String, dynamic> ? CommunityMember.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  /// Asks to be friends. Asking somebody who already asked accepts instead,
  /// which the backend decides — the answer is the state either way.
  Future<Friendship?> addFriend(int id) =>
      _friendCall('POST', 'members/$id/friend');

  Future<Friendship?> acceptFriend(int id) =>
      _friendCall('POST', 'members/$id/friend/accept');

  /// Cancels a sent request, declines a received one, or unfriends.
  Future<Friendship?> removeFriend(int id) =>
      _friendCall('DELETE', 'members/$id/friend');

  /// Members this one has blocked, so the list can be undone from settings.
  Future<List<CommunityMember>> blocked() =>
      _members(ApiConfig.endpoint('me/blocks'));

  /// Blocks or unblocks a member. Returns whether they are now blocked, or
  /// null when the call failed and nothing changed.
  ///
  /// The blocked member is never told, so there is nothing to report back
  /// beyond the viewer's own new state.
  Future<bool?> setBlocked(int id, bool blocked) async {
    try {
      final uri = ApiConfig.endpoint('members/$id/block');
      final response = await (blocked
              ? _client.post(uri, headers: auth.headers)
              : _client.delete(uri, headers: auth.headers))
          .timeout(ApiConfig.timeout);

      if (auth.wasRejected(response)) return null;
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> ? body['blocked'] == true : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<CommunityMember>> _members(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: auth.headers)
          .timeout(ApiConfig.timeout);

      if (auth.wasRejected(response)) return const [];
      if (response.statusCode != 200) return const [];

      final body = jsonDecode(response.body);
      final data = (body is Map<String, dynamic>) ? body['data'] : null;
      if (data is! List) return const [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(CommunityMember.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Returns where the pair now stands, or null when the call failed.
  Future<Friendship?> _friendCall(String method, String path) async {
    try {
      final uri = ApiConfig.endpoint(path);
      final response = await (method == 'DELETE'
              ? _client.delete(uri, headers: auth.headers)
              : _client.post(uri, headers: auth.headers))
          .timeout(ApiConfig.timeout);

      if (auth.wasRejected(response)) return null;
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;

      final state = body['friendship'];
      return state is String ? Friendship.fromName(state) : null;
    } catch (_) {
      return null;
    }
  }
}
