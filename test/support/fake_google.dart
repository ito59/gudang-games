import 'package:bandar_games/services/google_authenticator.dart';

/// A Google account chooser that answers however a test needs it to.
class FakeGoogleAuthenticator implements GoogleAuthenticator {
  FakeGoogleAuthenticator({
    this.idToken = 'google-id-token',
    this._configured = true,
    this.cancels = false,
    this.cancelDetail,
    this.failure,
  });

  final String idToken;
  bool _configured;

  /// Backing out of the chooser — which on Android is also what a
  /// misconfigured app looks like.
  final bool cancels;

  /// What the platform said, carried through to the UI.
  final String? cancelDetail;

  /// A message for a sign-in that genuinely went wrong.
  final String? failure;

  var signInCalls = 0;
  var signOutCalls = 0;

  /// Counts only the times a chooser would have been put in front of someone.
  var chooserOpened = 0;

  /// The client IDs the backend handed over, if any.
  String? adoptedServerClientId;

  @override
  bool get isConfigured => _configured;

  @override
  void adopt({String? serverClientId, String? iosClientId}) {
    adoptedServerClientId = serverClientId;
    _configured = (serverClientId ?? iosClientId ?? '').isNotEmpty;
  }

  @override
  Future<GoogleCredential> signIn() async {
    signInCalls++;

    // Mirrors the real authenticator, which refuses before showing anything.
    if (!_configured) {
      throw const GoogleAuthException('No Google client ID.');
    }

    if (failure != null) throw GoogleAuthException(failure!);

    chooserOpened++;
    if (cancels) {
      throw GoogleAuthException(
        'Sign-in closed before it finished.',
        dismissed: true,
        detail: cancelDetail,
      );
    }

    return GoogleCredential(idToken: idToken, email: 'newcomer@gmail.com');
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}
