import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/screens/edit_profile_screen.dart';
import 'package:bandar_games/screens/profile_screen.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/profile_scope.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_profile.dart';
import 'support/fonts.dart';
import 'support/images.dart';
import 'support/preferences.dart';

/// The page renders a member, so the golden needs a session and a loaded
/// profile — signed out it is only a sign-in prompt.
Widget _wrap(Widget child, Auth auth, ProfileController profile) {
  return ProfileScope(
    notifier: profile,
    child: AuthScope(
      notifier: auth,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  testWidgets('profile golden', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    resetPreferences();
    final server = FakeProfileServer();
    final auth = await signedInAuth(server);

    await tester.pumpWidget(
      _wrap(const ProfileScreen(), auth, await loadedProfile(server, auth)),
    );
    await tester.pumpAndSettle();
    await precacheAllImages(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/profile.png'),
    );
  });

  testWidgets('edit profile golden', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    resetPreferences();
    final server = FakeProfileServer();
    final auth = await signedInAuth(server);
    final profile = await loadedProfile(server, auth);

    await tester.pumpWidget(
      _wrap(EditProfileScreen(profile: profile.profile), auth, profile),
    );
    await tester.pumpAndSettle();
    await precacheAllImages(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/edit_profile.png'),
    );
  });
}
