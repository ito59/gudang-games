import 'package:flutter/widgets.dart';

import '../services/notification_settings.dart';
import '../services/push_messaging.dart';
import 'auth_scope.dart';

/// Keeps the backend told where this install is, and the install subscribed
/// to what its owner asked for.
///
/// Driven by the session rather than by a screen: a member who never opens
/// Profile → Notifications still expects to be told when somebody writes to
/// them, and somebody who signs out must stop receiving the last person's
/// messages on their phone.
class PushRegistrar extends ChangeNotifier {
  PushRegistrar({
    required this._messaging,
    required this._repository,
    this._auth,
  }) {
    _auth?.addListener(_onAuthChanged);
  }

  final PushMessaging _messaging;
  final NotificationRepository Function() _repository;
  final Auth? _auth;

  /// This install's token, once Firebase has issued one.
  String? _token;
  String? get token => _token;

  var _working = false;

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (_auth?.isSignedIn ?? false) {
      register();
      return;
    }

    // Signed out: the next person to pick up this phone must not be sent the
    // last one's messages.
    forget();
  }

  /// Registers this install against the signed-in member and applies their
  /// news preference to the topic.
  Future<void> register() async {
    if (_working || !(_auth?.isSignedIn ?? false)) return;
    _working = true;

    try {
      final token = _token ?? await _messaging.start();
      if (token == null) return;

      _token = token;
      final repository = _repository();
      await repository.registerDevice(token);

      final settings = await repository.fetch();
      if (settings == null) return;

      await applyNewsPreference(on: settings.news, topic: settings.newsTopic);
    } finally {
      _working = false;
    }
  }

  /// News goes out to a topic, so whether a phone hears it is decided on the
  /// phone — one call reaches every install, however many there are.
  Future<void> applyNewsPreference({
    required bool on,
    required String topic,
  }) async {
    if (on) {
      await _messaging.subscribe(topic);
    } else {
      await _messaging.unsubscribe(topic);
    }
  }

  /// Stops this install being reachable as whoever just left.
  Future<void> forget() async {
    final token = _token;
    if (token == null) return;

    await _repository().forgetDevice(token);
  }
}

class PushScope extends InheritedNotifier<PushRegistrar> {
  const PushScope({
    super.key,
    required PushRegistrar super.notifier,
    required super.child,
  });

  /// Null where no registrar was provided, which is most tests.
  static PushRegistrar? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PushScope>()?.notifier;
}
