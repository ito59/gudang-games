import 'dart:convert';

import 'package:http/http.dart' as http;

import '../state/auth_scope.dart';
import 'api_config.dart';

/// What a member wants to be told about.
class NotificationSettings {
  const NotificationSettings({
    this.chat = true,
    this.news = true,
    this.pushAvailable = false,
    this.newsTopic = 'news',
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      chat: json['chat'] != false,
      news: json['news'] != false,
      pushAvailable: json['push_available'] == true,
      newsTopic: (json['news_topic'] as String?) ?? 'news',
    );
  }

  final bool chat;
  final bool news;

  /// Whether this deployment can deliver anything at all. False when the
  /// server has no Firebase credentials — worth saying, rather than leaving
  /// somebody to wonder why a switch they turned on changes nothing.
  final bool pushAvailable;

  /// The topic an install subscribes to while [news] is on.
  final String newsTopic;

  NotificationSettings copyWith({bool? chat, bool? news}) =>
      NotificationSettings(
        chat: chat ?? this.chat,
        news: news ?? this.news,
        pushAvailable: pushAvailable,
        newsTopic: newsTopic,
      );
}

/// Reads and writes the member's notification preferences.
///
/// They live on the account rather than the phone: turning chat off on one
/// device should not leave a tablet buzzing.
class NotificationRepository {
  NotificationRepository({required this.auth, http.Client? client})
    : _client = client ?? http.Client();

  final Auth auth;
  final http.Client _client;

  /// Null when the settings could not be read.
  Future<NotificationSettings?> fetch() async {
    try {
      final response = await _client
          .get(ApiConfig.endpoint('me/notifications'), headers: auth.headers)
          .timeout(ApiConfig.timeout);

      return _settingsFrom(response);
    } catch (_) {
      return null;
    }
  }

  /// Saves one switch. Null when it did not save, so the screen can put the
  /// switch back rather than leaving it showing a preference nobody holds.
  Future<NotificationSettings?> save({bool? chat, bool? news}) async {
    try {
      final response = await _client
          .patch(
            ApiConfig.endpoint('me/notifications'),
            headers: {...auth.headers, 'Content-Type': 'application/json'},
            body: jsonEncode(_only(chat: chat, news: news)),
          )
          .timeout(ApiConfig.timeout);

      return _settingsFrom(response);
    } catch (_) {
      return null;
    }
  }

  /// Tells the backend where this install can be reached.
  Future<void> registerDevice(String token, {String? platform}) =>
      _device('POST', token, platform);

  /// Forgets this install, so the next person to use the phone is not sent
  /// somebody else's messages.
  Future<void> forgetDevice(String token) => _device('DELETE', token, null);

  Future<void> _device(String method, String token, String? platform) async {
    try {
      final uri = ApiConfig.endpoint('me/devices');
      final headers = {...auth.headers, 'Content-Type': 'application/json'};
      final body = jsonEncode({
        'token': token,
        ...?platform == null ? null : {'platform': platform},
      });

      final response = await (method == 'DELETE'
              ? _client.delete(uri, headers: headers, body: body)
              : _client.post(uri, headers: headers, body: body))
          .timeout(ApiConfig.timeout);

      auth.wasRejected(response);
    } catch (_) {
      // Registration retries on the next launch; nothing to tell anybody.
    }
  }

  /// Only what is being changed, so one switch never overwrites the other.
  static Map<String, bool> _only({bool? chat, bool? news}) {
    final body = <String, bool>{};
    if (chat != null) body['chat'] = chat;
    if (news != null) body['news'] = news;

    return body;
  }

  NotificationSettings? _settingsFrom(http.Response response) {
    if (auth.wasRejected(response)) return null;
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;

    return data is Map<String, dynamic>
        ? NotificationSettings.fromJson(data)
        : null;
  }
}
