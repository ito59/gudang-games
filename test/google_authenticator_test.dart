import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:bandar_games/services/google_authenticator.dart';

/// Stands in for the plugin's platform side, so the real authenticator's
/// handling of what Android reports can be tested without a device.
class _FakePlatform extends GoogleSignInPlatform with MockPlatformInterfaceMixin {
  _FakePlatform({this.error, this.idToken = 'id-token'});

  final GoogleSignInException? error;
  final String? idToken;

  InitParameters? initialisedWith;
  var signOutCalls = 0;

  @override
  Future<void> init(InitParameters params) async => initialisedWith = params;

  @override
  bool supportsAuthenticate() => true;

  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) async {
    final failure = error;
    if (failure != null) throw failure;

    return AuthenticationResults(
      user: const GoogleSignInUserData(
        id: '104729',
        email: 'newcomer@gmail.com',
        displayName: 'New Comer',
      ),
      authenticationTokens: AuthenticationTokenData(idToken: idToken),
    );
  }

  @override
  Future<void> signOut(SignOutParams params) async => signOutCalls++;

  @override
  Future<void> disconnect(DisconnectParams params) async {}

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) => null;

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) async => null;
}

GoogleSignInAuthenticator _authenticator({
  GoogleSignInException? error,
  String? idToken = 'id-token',
  String buildServerClientId = '',
}) {
  GoogleSignInPlatform.instance = _FakePlatform(error: error, idToken: idToken);

  return GoogleSignInAuthenticator(
    client: GoogleSignIn.instance,
    buildServerClientId: buildServerClientId,
    buildIosClientId: '',
  )..adopt(serverClientId: 'web.apps.googleusercontent.com');
}

void main() {
  test('a signed-in account hands back its ID token', () async {
    final credential = await _authenticator().signIn();

    expect(credential.idToken, 'id-token');
    expect(credential.email, 'newcomer@gmail.com');
  });

  test('a cancel keeps the reason Android gave', () async {
    // Android cannot tell a dismissal from a misconfigured app, so this is
    // the only line naming the cause — dropping it is what left a failed
    // sign-in looking like nothing happened at all.
    final authenticator = _authenticator(
      error: const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: '[28444] Developer console is not set up correctly.',
      ),
    );

    await expectLater(
      authenticator.signIn(),
      throwsA(
        isA<GoogleAuthException>()
            .having((e) => e.dismissed, 'dismissed', isTrue)
            .having(
              (e) => e.detail,
              'detail',
              '[28444] Developer console is not set up correctly.',
            )
            // The message must not name a cause the code cannot know.
            .having((e) => e.message, 'message', isNot(contains('SHA-1')))
            .having(
              (e) => e.message,
              'message',
              contains('reason below'),
            ),
      ),
    );
  });

  test('a configuration error says so plainly', () async {
    final authenticator = _authenticator(
      error: const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'serverClientId must be provided on Android',
      ),
    );

    await expectLater(
      authenticator.signIn(),
      throwsA(
        isA<GoogleAuthException>()
            .having((e) => e.dismissed, 'dismissed', isFalse)
            .having((e) => e.message, 'message', contains('not configured')),
      ),
    );
  });

  test('a missing ID token is not treated as a sign in', () async {
    // Google authenticated the person but issued nothing the backend can
    // check, which happens when no server client ID reached the plugin.
    await expectLater(
      _authenticator(idToken: null).signIn(),
      throwsA(
        isA<GoogleAuthException>().having(
          (e) => e.message,
          'message',
          contains('did not return an ID token'),
        ),
      ),
    );
  });

  test('the client ID reaches the plugin', () async {
    final authenticator = _authenticator();
    await authenticator.signIn();

    final platform = GoogleSignInPlatform.instance as _FakePlatform;
    expect(
      platform.initialisedWith?.serverClientId,
      'web.apps.googleusercontent.com',
    );
  });

  test('adopting a different client ID re-initialises the plugin', () async {
    final authenticator = _authenticator();
    await authenticator.signIn();

    authenticator.adopt(serverClientId: 'other.apps.googleusercontent.com');
    await authenticator.signIn();

    // Otherwise the plugin keeps asking Google for the previous audience.
    final platform = GoogleSignInPlatform.instance as _FakePlatform;
    expect(
      platform.initialisedWith?.serverClientId,
      'other.apps.googleusercontent.com',
    );
  });
}
