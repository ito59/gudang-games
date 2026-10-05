import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Client IDs baked into this build.
///
/// Normally empty: the backend hands the app its client IDs at startup, so
/// there is one place to configure and no way for the two to disagree. These
/// defines exist to override that — pinning a build to a specific client
/// without touching the server:
///
/// ```sh
/// flutter run \
///   --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>.apps.googleusercontent.com
/// ```
class GoogleConfig {
  const GoogleConfig._();

  static const serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
}

/// What the app needs back from Google.
class GoogleCredential {
  const GoogleCredential({required this.idToken, this.email});

  /// A signed JWT. The app never reads it — the backend verifies it.
  final String idToken;
  final String? email;
}

/// Why a Google sign-in produced no credential.
class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message, {this.dismissed = false, this.detail});

  final String message;

  /// The platform reported a cancel.
  ///
  /// Android cannot tell a real dismissal apart from several configuration
  /// failures — an unregistered SHA-1, a wrong package name, an account that
  /// is not a test user all arrive as "canceled". So this is a hint about
  /// tone, not proof that anybody chose to back out.
  final bool dismissed;

  /// What the platform itself said. Usually the only thing that names the
  /// real cause, so it is carried through rather than swallowed.
  final String? detail;

  @override
  String toString() => detail == null ? message : '$message ($detail)';
}

/// The plugin, behind a seam.
///
/// Screens and tests talk to this instead of `GoogleSignIn.instance`, which
/// needs a real platform channel and a real Google account to answer.
abstract interface class GoogleAuthenticator {
  /// False until a client ID is known, from the build or from the backend.
  /// The button stays out of the way rather than being shown broken.
  bool get isConfigured;

  /// Takes the client IDs the backend reported. A build-time define wins, so
  /// a pinned build is not quietly repointed by whatever server it talks to.
  void adopt({String? serverClientId, String? iosClientId});

  /// Throws [GoogleAuthException] when no credential came back, including
  /// when the chooser was dismissed.
  Future<GoogleCredential> signIn();

  Future<void> signOut();
}

class GoogleSignInAuthenticator implements GoogleAuthenticator {
  GoogleSignInAuthenticator({
    GoogleSignIn? client,
    String? buildServerClientId,
    String? buildIosClientId,
  }) : _client = client ?? GoogleSignIn.instance,
       _buildServerClientId = buildServerClientId ?? GoogleConfig.serverClientId,
       _buildIosClientId = buildIosClientId ?? GoogleConfig.iosClientId;

  final GoogleSignIn _client;

  /// Compiled in by `--dart-define`; empty in an ordinary build. A parameter
  /// rather than a direct read so the precedence below can be tested.
  final String _buildServerClientId;
  final String _buildIosClientId;
  Future<void>? _initialized;

  String? _remoteServerClientId;
  String? _remoteIosClientId;

  String get _serverClientId => _buildServerClientId.isNotEmpty
      ? _buildServerClientId
      : (_remoteServerClientId ?? '');

  String get _iosClientId => _buildIosClientId.isNotEmpty
      ? _buildIosClientId
      : (_remoteIosClientId ?? '');

  @override
  bool get isConfigured =>
      _serverClientId.isNotEmpty || _iosClientId.isNotEmpty;

  /// The ID that would actually be used, for tests of the precedence rule.
  @visibleForTesting
  String get debugServerClientId => _serverClientId;

  @override
  void adopt({String? serverClientId, String? iosClientId}) {
    if (serverClientId == _remoteServerClientId &&
        iosClientId == _remoteIosClientId) {
      return;
    }

    _remoteServerClientId = serverClientId;
    _remoteIosClientId = iosClientId;

    // Whatever was initialised was initialised with the old IDs.
    _initialized = null;
  }

  /// `initialize` has to finish before `authenticate`, and it is done once for
  /// the process — holding the future rather than a flag means two taps in a
  /// row cannot start it twice.
  Future<void> _initialize() {
    return _initialized ??= _client.initialize(
      clientId: _iosClientId.isEmpty ? null : _iosClientId,
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
  }

  @override
  Future<GoogleCredential> signIn() async {
    if (!isConfigured) {
      throw const GoogleAuthException(
        'No Google client ID. Set GOOGLE_SERVER_CLIENT_ID in backend/.env — '
        'see docs/google-sign-in.md.',
      );
    }

    try {
      await _initialize();
    } catch (error) {
      _initialized = null; // Let a later attempt try again.
      throw const GoogleAuthException('Google sign-in could not start.');
    }

    if (!_client.supportsAuthenticate()) {
      throw const GoogleAuthException(
        'Google sign-in is not available on this device.',
      );
    }

    final GoogleSignInAccount account;
    try {
      account = await _client.authenticate();
    } on GoogleSignInException catch (error) {
      // The console line is what a developer will actually read while
      // setting this up; the UI only has room for a sentence.
      debugPrint('Google sign-in failed: ${error.code} — ${error.description}');

      throw GoogleAuthException(
        _messageFor(error),
        dismissed: error.code == GoogleSignInExceptionCode.canceled,
        detail: error.description,
      );
    } catch (error) {
      debugPrint('Google sign-in failed: $error');
      throw GoogleAuthException(
        'Google sign-in did not complete.',
        detail: '$error',
      );
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      // Happens when the build has no serverClientId: Google authenticates the
      // person but issues nothing the backend can check.
      throw const GoogleAuthException(
        'Google did not return an ID token. Check the server client ID.',
      );
    }

    return GoogleCredential(idToken: idToken, email: account.email);
  }

  @override
  Future<void> signOut() async {
    // Best effort: the local session is being dropped either way, and this
    // only decides whether Google offers the account chooser next time.
    try {
      await _client.signOut();
    } catch (_) {}
  }

  static String _messageFor(GoogleSignInException error) => switch (error.code) {
    // Android reports several unrelated failures as a cancel — a real
    // dismissal, an unregistered SHA-1, an account the device cannot
    // re-verify. Naming one of them would be a guess, so the line below
    // points at the detail, which is the part that actually says which.
    GoogleSignInExceptionCode.canceled =>
      'Sign-in closed before it finished. If you did not close it yourself, '
          'the reason below is from Google — see docs/google-sign-in.md.',
    GoogleSignInExceptionCode.clientConfigurationError ||
    GoogleSignInExceptionCode.providerConfigurationError =>
      'Google sign-in is not configured for this app build.',
    GoogleSignInExceptionCode.uiUnavailable => 'Google sign-in could not open.',
    GoogleSignInExceptionCode.interrupted => 'Google sign-in was interrupted.',
    _ => 'Google sign-in failed.',
  };
}
