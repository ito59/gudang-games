import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import 'auth_scope.dart';

/// Tells the backend this member has the app open, which is all "online"
/// means to everyone else.
///
/// A heartbeat every [interval] while the app is in the foreground and
/// somebody is signed in; one goodbye when it goes to the background, so the
/// member drops off the "Online now" strip at once instead of when the
/// server's window runs out. Any other signed-in call counts as a beat too,
/// so this only has to cover the stretches where a screen sits idle.
class PresenceTracker with WidgetsBindingObserver {
  PresenceTracker({
    required this._auth,
    http.Client? client,
    this.interval = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  final Auth _auth;
  final http.Client _client;
  final Duration interval;

  Timer? _timer;
  var _foreground = true;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_sync);
    _sync();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.removeListener(_sync);
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `inactive` is a system sheet over the app — the Google account
    // chooser, a permission prompt — and the member is still here.
    if (state == AppLifecycleState.inactive) return;

    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    final beating = _timer != null;

    if (_auth.isSignedIn && _foreground) {
      if (beating) return;
      _send('POST');
      _timer = Timer.periodic(interval, (_) => _send('POST'));
      return;
    }

    _timer?.cancel();
    _timer = null;

    // Signing out is marked away by the server as part of the logout call.
    if (beating && _auth.isSignedIn) _send('DELETE');
  }

  Future<void> _send(String method) async {
    try {
      final uri = ApiConfig.endpoint('me/presence');
      final response = await (method == 'DELETE'
              ? _client.delete(uri, headers: _auth.headers)
              : _client.post(uri, headers: _auth.headers))
          .timeout(ApiConfig.timeout);

      _auth.wasRejected(response);
    } catch (_) {
      // A missed beat is covered by the server's window; nothing to show.
    }
  }
}
