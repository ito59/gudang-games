import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bandar_games/data/mock_data.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/profile_scope.dart';

/// A stand-in for `/api/v1/me`, holding the member between calls so an edit
/// made in one request is visible in the next.
class FakeProfileServer {
  /// Deliberately a different person from `defaultProfile`. If the fake
  /// served the same member as the bundled placeholder, a test could not tell
  /// backend data from mock data — and a leak of one into the other would
  /// look like a pass.
  FakeProfileServer({
    this.name = 'Sinta Maharani',
    this.username = 'sintam',
    this.bio = 'Ranked grinder, weekends only.',
    this.location = 'Yogyakarta, ID',
    this.googleAvatar,
    this.takenUsernames = const <String>{},
    this.failReads = false,
  });

  String name;
  String username;
  String bio;
  String location;
  String? googleAvatar;

  /// The uploaded photo, as a URL — what the backend answers once one is on
  /// disk. Null means the member has none.
  String? uploadedAvatar;

  /// Makes the upload fail the way an oversized file does.
  bool rejectUploads = false;

  /// Handles that belong to somebody else, so a save collides the way the
  /// real uniqueness rule does.
  final Set<String> takenUsernames;

  bool failReads;

  final List<String> calls = [];

  Map<String, Object?> get _payload => {
    'id': 1,
    'name': name,
    'handle': username,
    'bio': bio,
    'location': location,
    'avatar': uploadedAvatar,
    'google_avatar': googleAvatar,
    'accent': '#7C3AED',
    'games_owned': 42,
    'hours_played': 365,
    'achievements': 17,
  };

  http.Client get client => MockClient((request) async {
    final path = request.url.path;
    calls.add('${request.method} $path');

    if (path.endsWith('/login')) {
      return _json({
        'token': 'test-token',
        'user': {'data': _payload},
      });
    }

    if (path.endsWith('/config')) {
      return _json({
        'google': {'enabled': false, 'server_client_id': null},
      });
    }

    if (path.endsWith('/me') && request.method == 'GET') {
      if (failReads) return _json({'message': 'nope'}, 500);
      return _json({'data': _payload});
    }

    if (path.endsWith('/me') && request.method == 'PATCH') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final wanted = (body['username'] as String?) ?? '';

      if (takenUsernames.contains(wanted)) {
        return _json({
          'message': 'The given data was invalid.',
          'errors': {
            'username': ['That username is taken.'],
          },
        }, 422);
      }

      name = (body['name'] as String?) ?? name;
      username = wanted;
      bio = (body['bio'] as String?) ?? '';
      location = (body['location'] as String?) ?? '';

      return _json({'data': _payload});
    }

    if (path.endsWith('/me/avatar')) {
      if (request.method == 'DELETE') {
        uploadedAvatar = null;
        return _json({'data': _payload});
      }

      if (rejectUploads) {
        return _json({
          'message': 'The given data was invalid.',
          'errors': {
            'photo': ['That photo is larger than 8 MB.'],
          },
        }, 422);
      }

      uploadedAvatar = 'https://cdn.test/avatars/me.jpg';
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

/// An [Auth] already holding a session against [server].
Future<Auth> signedInAuth(FakeProfileServer server) async {
  final auth = Auth(client: server.client);
  final error = await auth.signIn(email: 'a@b.c', password: 'password');
  if (error != null) throw StateError('fake sign in failed: $error');
  return auth;
}

/// A profile controller wired to [server] and already loaded.
Future<ProfileController> loadedProfile(
  FakeProfileServer server,
  Auth auth,
) async {
  final controller = ProfileController(
    defaultProfile,
    auth: auth,
    client: server.client,
  );
  await controller.load();
  return controller;
}
