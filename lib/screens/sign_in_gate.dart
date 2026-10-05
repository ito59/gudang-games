import 'package:flutter/material.dart';

import '../state/auth_scope.dart';
import 'sign_in_screen.dart';

/// Screens and actions that need an account behind them.
///
/// Two shapes, because there are two situations. [ensureSignedIn] is for an
/// action somebody just took — sign in, then carry on with it. [requireSignIn]
/// is for a whole screen that cannot exist without a session: it sends them
/// to sign in and, if they decline, takes them back where they came from
/// rather than leaving them on a page that can only fail.
mixin SignInGate<T extends StatefulWidget> on State<T> {
  var _asking = false;

  /// Writing needs an account. Returns whether one is now signed in.
  Future<bool> ensureSignedIn() async {
    if (AuthScope.of(context).isSignedIn) return true;

    final signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
    return signedIn ?? false;
  }

  /// Sends an unauthenticated visitor to sign in, and pops this screen if
  /// they choose not to.
  ///
  /// Safe to call from `didChangeDependencies`: the push is deferred past the
  /// current frame, and a second call while the prompt is already open does
  /// nothing.
  void requireSignIn() {
    if (_asking || AuthScope.of(context).isSignedIn) return;
    _asking = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final navigator = Navigator.of(context);
      final signedIn = await ensureSignedIn();
      _asking = false;

      if (!signedIn && mounted && navigator.canPop()) navigator.pop();
    });
  }
}
