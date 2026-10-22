import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../l10n/language.dart';
import '../models/user_profile.dart';
import '../services/api_config.dart';
import '../services/photo_picker.dart';
import 'auth_scope.dart';

/// Holds the signed-in member's profile, backed by `/api/v1/me`.
///
/// [profile] is only the member's own data once [isLive] is true; until then
/// it is the bundled placeholder, which the profile page must not present as
/// somebody's real account.
class ProfileController extends ChangeNotifier {
  ProfileController(this._fallback, {this._auth, http.Client? client})
    : _profile = _fallback,
      _client = client ?? http.Client() {
    // Signing in and out is what decides whose profile this is.
    _auth?.addListener(_onAuthChanged);
  }

  final UserProfile _fallback;
  final Auth? _auth;
  final http.Client _client;

  UserProfile _profile;
  var _isLive = false;
  var _loading = false;

  UserProfile get profile => _profile;

  /// Whether [profile] came from the backend rather than the placeholder.
  bool get isLive => _isLive;

  bool get isLoading => _loading;

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (_auth?.isSignedIn ?? false) {
      load();
      return;
    }

    // Signed out: drop the member's data rather than leaving it on screen.
    if (!_isLive) return;
    _profile = _fallback;
    _isLive = false;
    notifyListeners();
  }

  Future<void> load() async {
    final auth = _auth;
    if (auth == null || !auth.isSignedIn) return;

    _loading = true;
    notifyListeners();

    try {
      final response = await _client
          .get(ApiConfig.endpoint('me'), headers: auth.headers)
          .timeout(ApiConfig.timeout);

      auth.wasRejected(response);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (data is Map<String, dynamic>) {
          _profile = UserProfile.fromJson(
            data,
            fallbackAvatar: _fallback.avatar,
          );
          _isLive = true;
        }
      }
    } catch (_) {
      // Leave whatever is held; the page says when nothing loaded.
    }

    _loading = false;
    notifyListeners();
  }

  /// Saves the edited profile. Returns null on success, or a message —
  /// the server owns the rules that matter here, like whether a username is
  /// already taken, so its wording is passed straight through.
  Future<String?> save(UserProfile updated) async {
    final auth = _auth;

    if (auth == null || !auth.isSignedIn) {
      // No backend in this build or nobody signed in: keep it local so the
      // screen still behaves, and say nothing went to a server.
      if (updated == _profile) return null;
      _profile = updated;
      notifyListeners();
      return null;
    }

    try {
      final response = await _client
          .patch(
            ApiConfig.endpoint('me'),
            headers: {...auth.headers, 'Content-Type': 'application/json'},
            body: jsonEncode(updated.toEditJson()),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (data is Map<String, dynamic>) {
          _profile = UserProfile.fromJson(
            data,
            fallbackAvatar: _fallback.avatar,
          );
          _isLive = true;
          notifyListeners();
          return null;
        }
      }

      return _messageFrom(response);
    } catch (_) {
      return tr(
        'Tidak bisa terhubung ke server.',
        'Could not reach the server.',
      );
    }
  }

  /// Uploads a new profile photo. Returns null on success, or a message —
  /// the server owns the size and type rules, so its wording is passed
  /// straight through.
  Future<String?> setPhoto(PickedPhoto photo) async {
    final auth = _auth;
    if (auth == null || !auth.isSignedIn) {
      return tr('Silakan masuk dulu.', 'Please sign in first.');
    }

    try {
      final request =
          http.MultipartRequest('POST', ApiConfig.endpoint('me/avatar'))
            ..headers.addAll(auth.headers)
            ..files.add(
              http.MultipartFile.fromBytes(
                'photo',
                photo.bytes,
                filename: photo.filename,
              ),
            );

      final response = await http.Response.fromStream(
        await _client.send(request).timeout(ApiConfig.timeout),
      );

      return _adopt(response);
    } catch (_) {
      return tr(
        'Tidak bisa terhubung ke server.',
        'Could not reach the server.',
      );
    }
  }

  /// Drops the photo and goes back to initials.
  Future<String?> removePhoto() async {
    final auth = _auth;
    if (auth == null || !auth.isSignedIn) {
      return tr('Silakan masuk dulu.', 'Please sign in first.');
    }

    try {
      final response = await _client
          .delete(ApiConfig.endpoint('me/avatar'), headers: auth.headers)
          .timeout(ApiConfig.timeout);

      return _adopt(response);
    } catch (_) {
      return tr(
        'Tidak bisa terhubung ke server.',
        'Could not reach the server.',
      );
    }
  }

  /// Takes the member out of a `/me` shaped answer, or explains why not.
  String? _adopt(http.Response response) {
    _auth?.wasRejected(response);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is Map<String, dynamic>) {
        _profile = UserProfile.fromJson(data, fallbackAvatar: _fallback.avatar);
        _isLive = true;
        notifyListeners();
        return null;
      }
    }

    return _messageFrom(response);
  }

  String _messageFrom(http.Response response) {
    if (response.statusCode == 401) {
      return tr('Silakan masuk lagi.', 'Please sign in again.');
    }

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

    return tr(
      'Gagal menyimpan (${response.statusCode}).',
      'That did not save (${response.statusCode}).',
    );
  }
}

/// Exposes the [ProfileController] to the subtree and rebuilds dependents
/// whenever the profile changes.
class ProfileScope extends InheritedNotifier<ProfileController> {
  const ProfileScope({
    super.key,
    required ProfileController super.notifier,
    required super.child,
  });

  static ProfileController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProfileScope>();
    assert(scope != null, 'No ProfileScope found in context');
    return scope!.notifier!;
  }
}
