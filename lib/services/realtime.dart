import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../state/auth_scope.dart';
import 'api_config.dart';

/// Where the socket lives, as the backend reports it at `/config`.
class RealtimeConfig {
  const RealtimeConfig({
    required this.key,
    required this.host,
    required this.port,
    required this.scheme,
  });

  static RealtimeConfig? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['enabled'] != true) return null;

    final key = json['key'] as String?;
    final host = json['host'] as String?;
    if (key == null || key.isEmpty || host == null || host.isEmpty) return null;

    return RealtimeConfig(
      key: key,
      host: host,
      port: (json['port'] as num?)?.toInt() ?? 443,
      scheme: (json['scheme'] as String?) == 'wss' ? 'wss' : 'ws',
    );
  }

  final String key;
  final String host;
  final int port;
  final String scheme;

  Uri get uri => Uri.parse(
    '$scheme://$host:$port/app/$key?protocol=7&client=flutter&version=1.0',
  );
}

/// One event pushed from the server.
class RealtimeEvent {
  const RealtimeEvent({
    required this.channel,
    required this.name,
    required this.data,
  });

  final String channel;
  final String name;
  final Map<String, dynamic> data;
}

/// A live connection to the server, behind a seam.
///
/// Tests inject their own rather than opening a socket, the same arrangement
/// [GoogleAuthenticator] and [PhotoPicker] use.
abstract class Realtime {
  Stream<RealtimeEvent> get events;

  /// This connection's id, which a send includes so the server can leave the
  /// sender out of its own broadcast. Null until connected.
  String? get socketId;

  Future<void> subscribe(String channel);
  Future<void> unsubscribe(String channel);
  Future<void> close();
}

/// Talks to Laravel Reverb.
///
/// Reverb speaks the Pusher protocol, and the part this app needs is small
/// enough to write directly: connect, authorise a private channel against our
/// own API, subscribe, and read events. That keeps the transport in Dart —
/// testable, and the same on every platform — instead of behind a plugin.
class ReverbRealtime implements Realtime {
  ReverbRealtime({
    required this.config,
    required this.auth,
    http.Client? client,
    WebSocketChannel Function(Uri uri)? connect,
  }) : _client = client ?? http.Client(),
       _connect = connect ?? WebSocketChannel.connect;

  /// Asked for on the first connect rather than passed in: the settings come
  /// from `/config`, which is still in flight when the app builds its state.
  final Future<RealtimeConfig?> Function() config;

  final Auth auth;
  final http.Client _client;
  final WebSocketChannel Function(Uri uri) _connect;

  final _events = StreamController<RealtimeEvent>.broadcast();

  /// Channels the app wants to be on, so a reconnect can restore them.
  final _wanted = <String>{};

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _listener;
  String? _socketId;
  Completer<void>? _connected;
  Timer? _retry;
  var _attempt = 0;
  var _closed = false;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  String? get socketId => _socketId;

  @override
  Future<void> subscribe(String channel) async {
    _wanted.add(channel);
    await _ensureConnected();
    await _sendSubscribe(channel);
  }

  @override
  Future<void> unsubscribe(String channel) async {
    _wanted.remove(channel);
    _send({
      'event': 'pusher:unsubscribe',
      'data': {'channel': channel},
    });
  }

  @override
  Future<void> close() async {
    _closed = true;
    _retry?.cancel();
    await _listener?.cancel();
    await _channel?.sink.close();
    await _events.close();
  }

  Future<void> _ensureConnected() async {
    if (_socketId != null) return;
    if (_connected != null) return _connected!.future;

    final settings = await config();
    if (settings == null) {
      // This deployment has no socket. Nothing to retry towards.
      return;
    }

    final ready = Completer<void>();
    _connected = ready;

    try {
      final channel = _connect(settings.uri);
      _channel = channel;
      _listener = channel.stream.listen(
        _onFrame,
        onDone: _onDropped,
        onError: (_) => _onDropped(),
        cancelOnError: true,
      );
    } catch (_) {
      _connected = null;
      _scheduleRetry();
      return;
    }

    // The handshake is what hands over the socket id; without it a private
    // channel cannot be authorised.
    return ready.future.timeout(
      ApiConfig.timeout,
      onTimeout: () {
        _connected = null;
        _scheduleRetry();
      },
    );
  }

  void _onFrame(dynamic raw) {
    final frame = _decode(raw);
    if (frame == null) return;

    final name = frame['event'] as String?;
    final data = _payload(frame['data']);

    if (name == 'pusher:connection_established') {
      _socketId = data['socket_id'] as String?;
      _attempt = 0;
      if (!(_connected?.isCompleted ?? true)) _connected!.complete();
      return;
    }

    if (name == 'pusher:ping') {
      _send({'event': 'pusher:pong', 'data': {}});
      return;
    }

    if (name == null || name.startsWith('pusher')) return;

    _events.add(
      RealtimeEvent(
        channel: (frame['channel'] as String?) ?? '',
        name: name,
        data: data,
      ),
    );
  }

  /// A private channel is only joinable with a signature from our own API,
  /// which is where the "are you in this conversation" rule lives.
  Future<void> _sendSubscribe(String channel) async {
    final socketId = _socketId;
    if (socketId == null) return;

    try {
      final response = await _client
          .post(
            ApiConfig.broadcastAuth,
            headers: {...auth.headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'socket_id': socketId,
              'channel_name': channel,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body);
      final signature = body is Map<String, dynamic> ? body['auth'] : null;
      if (signature is! String) return;

      _send({
        'event': 'pusher:subscribe',
        'data': {'auth': signature, 'channel': channel},
      });
    } catch (_) {
      // Left unsubscribed; a reconnect tries the whole set again.
    }
  }

  void _send(Map<String, dynamic> frame) {
    try {
      _channel?.sink.add(jsonEncode(frame));
    } catch (_) {
      // The socket went away; the drop handler deals with it.
    }
  }

  void _onDropped() {
    _socketId = null;
    _connected = null;
    _channel = null;
    _scheduleRetry();
  }

  /// Backs off rather than hammering a server that is down, and gives up
  /// nothing: the wanted channels are restored on the next success.
  void _scheduleRetry() {
    if (_closed || _retry != null) return;

    final seconds = [1, 2, 5, 10, 20][_attempt.clamp(0, 4)];
    _attempt++;

    _retry = Timer(Duration(seconds: seconds), () async {
      _retry = null;
      if (_closed) return;

      await _ensureConnected();
      if (_socketId == null) return;

      for (final channel in _wanted) {
        await _sendSubscribe(channel);
      }
    });
  }

  static Map<String, dynamic>? _decode(dynamic raw) {
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Pusher nests its payload as a JSON string inside the frame.
  static Map<String, dynamic> _payload(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // Not JSON; nothing to read.
      }
    }
    return const {};
  }
}
