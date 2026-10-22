import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/language.dart';
import '../services/api_config.dart';
import '../services/google_authenticator.dart';
import '../services/realtime.dart';

/// The signed-in member, as far as the app needs to know.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.handle,
    this.accent,
    this.avatar,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: (json['name'] as String?) ?? '',
    handle: (json['handle'] as String?) ?? '',
    accent: json['accent'] as String?,
    avatar: json['avatar'] as String?,
  );

  final int id;
  final String name;
  final String handle;
  final String? accent;
  final String? avatar;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'handle': handle,
    'accent': accent,
    'avatar': avatar,
  };
}

/// Holds the API token and who it belongs to.
///
/// Posting, liking and commenting are writes the backend attributes to a
/// member, so they need a token — reading the feed does not.
class Auth extends ChangeNotifier {
  Auth({
    http.Client? client,
    SharedPreferencesAsync? preferences,
    this._google,
  }) : _client = client ?? http.Client(),
       _preferences = preferences ?? SharedPreferencesAsync();

  static const tokenKey = 'auth_token_v1';
  static const userKey = 'auth_user_v1';

  final http.Client _client;
  final SharedPreferencesAsync _preferences;

  /// Null in builds and tests that never offer Google sign-in.
  final GoogleAuthenticator? _google;

  String? _lastGoogleDetail;

  /// Where the live socket is, once `/config` has answered. Null on a
  /// deployment with realtime turned off.
  RealtimeConfig? _realtime;

  /// Completed when `/config` has been asked, answered or not, so a caller
  /// waiting on the socket settings is never left hanging.
  final _configAsked = Completer<void>();

  /// The socket settings, waiting for `/config` if it is still in flight.
  Future<RealtimeConfig?> realtimeConfig() async {
    if (!_configAsked.isCompleted) {
      await _configAsked.future;
    }
    return _realtime;
  }

  /// What the platform said about the last failed Google sign-in, if
  /// anything. Shown under the message, because it usually names the cause.
  String? get lastGoogleDetail => _lastGoogleDetail;

  String? _token;
  AuthUser? _user;
  var _loaded = false;

  bool get isLoaded => _loaded;

  /// Whether this build can offer the Google button at all.
  bool get supportsGoogle => _google?.isConfigured ?? false;
  bool get isSignedIn => _token != null;
  AuthUser? get user => _user;
  String? get token => _token;

  /// Restores a previous session so signing in is a one-time step, and asks
  /// the backend which Google client this deployment uses.
  ///
  /// The session comes back first: the Google lookup is a network round trip,
  /// and screens that read the feed on their first frame would otherwise send
  /// it anonymously and get every post back unliked.
  Future<void> load() async {
    try {
      _token = await _preferences.getString(tokenKey);
      final raw = await _preferences.getString(userKey);
      if (raw != null && raw.isNotEmpty) {
        _user = AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      _token = null;
      _user = null;
    }

    _loaded = true;
    notifyListeners();

    await _loadGoogleConfig();
  }

  /// Returns null on success, or a message to show the person.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client
          .post(
            ApiConfig.endpoint('login'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
              'device_name': 'bandar-games-app',
            }),
          )
          .timeout(ApiConfig.timeout);

      return _adoptSession(
        response,
        fallback: tr(
          'Email atau kata sandi tidak cocok.',
          'Those details did not work.',
        ),
      );
    } catch (error) {
      return tr(
        'Tidak bisa terhubung ke server.',
        'Could not reach the server.',
      );
    }
  }

  /// Takes the token and member out of a sign-in response, or explains why it
  /// could not. Both sign-in routes answer in the same shape.
  Future<String?> _adoptSession(
    http.Response response, {
    required String fallback,
  }) async {
    final Object? body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      return tr(
        'Gagal masuk (${response.statusCode}).',
        'Sign in failed (${response.statusCode}).',
      );
    }

    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      if (body is Map<String, dynamic>) {
        // Laravel returns field errors; show the first one verbatim.
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return '${first.first}';
        }
        if (body['message'] is String) return body['message'] as String;
        return fallback;
      }
      return tr(
        'Gagal masuk (${response.statusCode}).',
        'Sign in failed (${response.statusCode}).',
      );
    }

    final token = body['token'];
    final user = body['user'];
    if (token is! String || token.isEmpty || user is! Map<String, dynamic>) {
      return fallback;
    }

    _token = token;
    _user = user['data'] is Map<String, dynamic>
        ? AuthUser.fromJson(user['data'] as Map<String, dynamic>)
        : AuthUser.fromJson(user);

    await _persist();
    notifyListeners();
    return null;
  }

  /// Asks the backend for its Google client IDs.
  ///
  /// Skipped when this build has no Google support at all, so an app without
  /// it never makes the call — and a server that is down or has Google turned
  /// off simply leaves the button hidden.
  Future<void> _loadGoogleConfig() async {
    try {
      final response = await _client
          .get(
            ApiConfig.endpoint('config'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return;

      _realtime = RealtimeConfig.fromJson(body['realtime']);

      final google = _google;
      if (google == null) return;

      final settings = body['google'];
      if (settings is! Map<String, dynamic>) return;
      if (settings['enabled'] != true) return;

      google.adopt(
        serverClientId: settings['server_client_id'] as String?,
        iosClientId: settings['ios_client_id'] as String?,
      );
    } catch (_) {
      // Nothing to do: the button stays hidden until a later run gets through.
    } finally {
      if (!_configAsked.isCompleted) _configAsked.complete();
    }
  }

  /// Signs in through Google, exchanging its ID token for one of ours.
  ///
  /// Returns null on success, or a message to show. A dismissed chooser is
  /// reported too: on Android it is indistinguishable from a misconfigured
  /// app, and staying silent about it is what makes that failure so hard to
  /// place.
  Future<String?> signInWithGoogle() async {
    final google = _google;
    if (google == null) {
      return tr(
        'Versi aplikasi ini tidak mendukung masuk dengan Google.',
        'This build has no Google sign-in.',
      );
    }

    // The client ID arrives with the config at launch. If that call failed —
    // no signal, a VPN in the way — ask again now rather than failing until
    // the app is restarted.
    if (!google.isConfigured) await _loadGoogleConfig();

    final GoogleCredential credential;
    try {
      credential = await google.signIn();
    } on GoogleAuthException catch (error) {
      _lastGoogleDetail = error.detail;
      return error.message;
    }

    _lastGoogleDetail = null;

    try {
      final response = await _client
          .post(
            ApiConfig.endpoint('auth/google'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'id_token': credential.idToken,
              'device_name': 'bandar-games-app',
            }),
          )
          .timeout(ApiConfig.timeout);

      return _adoptSession(
        response,
        fallback: tr(
          'Masuk dengan Google ditolak.',
          'Google sign-in was refused.',
        ),
      );
    } catch (_) {
      return tr(
        'Tidak bisa terhubung ke server.',
        'Could not reach the server.',
      );
    }
  }

  Future<void> signOut() async {
    final token = _token;
    _token = null;
    _user = null;
    notifyListeners();
    await _persist();
    await _google?.signOut();

    // Best effort: the local session is already gone either way.
    if (token != null) {
      try {
        await _client
            .post(
              ApiConfig.endpoint('logout'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(ApiConfig.timeout);
      } catch (_) {}
    }
  }

  /// Whether the server refused this token, dropping the session if it did.
  ///
  /// A token can stop being accepted for reasons the app cannot see: revoked
  /// on the server, wiped with the database, or issued by a different backend
  /// this build no longer points at. Keeping it leaves somebody who looks
  /// signed in — no prompt, their name in the header — while everything that
  /// needs a token quietly fails. Better to admit the session is gone and ask
  /// them to sign in again.
  ///
  /// Not [signOut]: there is no point telling a server to revoke a token it
  /// has already refused.
  bool wasRejected(http.Response response) {
    if (response.statusCode != 401 || _token == null) return false;

    _token = null;
    _user = null;
    notifyListeners();
    unawaited(_persist());

    return true;
  }

  /// Headers for an authenticated request; empty when signed out.
  Map<String, String> get headers => {
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<void> _persist() async {
    try {
      if (_token == null) {
        await _preferences.remove(tokenKey);
        await _preferences.remove(userKey);
      } else {
        await _preferences.setString(tokenKey, _token!);
        await _preferences.setString(userKey, jsonEncode(_user?.toJson()));
      }
    } catch (_) {}
  }
}

class AuthScope extends InheritedNotifier<Auth> {
  const AuthScope({
    super.key,
    required Auth super.notifier,
    required super.child,
  });

  static Auth of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope found in context');
    return scope!.notifier!;
  }
}
