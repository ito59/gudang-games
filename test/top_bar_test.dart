import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/data/mock_data.dart';
import 'package:bandar_games/screens/home_screen.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/profile_scope.dart';
import 'package:bandar_games/widgets/profile_photo.dart';
import 'package:bandar_games/theme/app_icons.dart';

import 'support/fake_games.dart';
import 'support/fake_profile.dart';
import 'support/preferences.dart';
import 'support/scopes.dart';

/// The Image whose provider is the given URL. The picture itself never loads
/// in a test — what matters is that the header asked for the member's photo
/// rather than the bundled art.
Finder _networkImage(String url) => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is NetworkImage &&
      (widget.image as NetworkImage).url == url,
);

Finder get _bundledAvatar => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == avatarImage,
);

Future<void> _pumpHome(
  WidgetTester tester, {
  ProfileController? profile,
  Auth? auth,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    wrapScreen(
      HomeScreen(repository: fakeGameRepository()),
      profile: profile,
      auth: auth,
    ),
  );
  await tester.pumpAndSettle();
}

/// The brand lockup, which the avatar now sits to the right of.
final _brand = find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == 'BandarGames',
);

void main() {
  testWidgets('the avatar sits at the far right of the header', (tester) async {
    resetPreferences();
    final server = FakeProfileServer();
    final auth = await signedInAuth(server);
    final profile = await loadedProfile(server, auth);

    await _pumpHome(tester, profile: profile, auth: auth);

    final avatar = tester.getCenter(find.byType(ProfilePhoto).first);
    final brand = tester.getCenter(_brand);
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;

    expect(avatar.dx, greaterThan(brand.dx));
    // Far right, not merely right of the wordmark.
    expect(avatar.dx, greaterThan(width * 0.8));
  });

  testWidgets('the notification bell is gone for now', (tester) async {
    await _pumpHome(tester);

    expect(find.byIcon(AppIcons.notifications), findsNothing);
  });

  testWidgets('the header shows the signed-in member\'s own photo', (
    tester,
  ) async {
    resetPreferences();
    final server = FakeProfileServer()
      ..uploadedAvatar = 'https://cdn.test/avatars/me.jpg';
    final auth = await signedInAuth(server);
    final profile = await loadedProfile(server, auth);

    await _pumpHome(tester, profile: profile, auth: auth);

    // The bundled art is still in the tree as the error fallback — no photo
    // ever loads in a test — so what matters is that the header asked for
    // theirs at all.
    expect(_networkImage('https://cdn.test/avatars/me.jpg'), findsOneWidget);
  });

  testWidgets('a Google photo is used when there is no upload', (tester) async {
    resetPreferences();
    final server = FakeProfileServer(googleAvatar: 'https://google/photo.jpg');
    final auth = await signedInAuth(server);
    final profile = await loadedProfile(server, auth);

    await _pumpHome(tester, profile: profile, auth: auth);

    expect(_networkImage('https://google/photo.jpg'), findsOneWidget);
  });

  testWidgets('signed out, nobody\'s face is shown', (tester) async {
    await _pumpHome(tester);

    // The controller still holds the bundled sample member when nobody is
    // signed in. Drawing their face here would tell a visitor they are
    // logged in as somebody.
    expect(_bundledAvatar, findsNothing);
    expect(find.byIcon(AppIcons.accountCircle), findsOneWidget);
  });

  testWidgets('a member with no photo of their own gets the bundled art', (
    tester,
  ) async {
    resetPreferences();
    final server = FakeProfileServer();
    final auth = await signedInAuth(server);
    final profile = await loadedProfile(server, auth);

    await _pumpHome(tester, profile: profile, auth: auth);

    expect(_bundledAvatar, findsOneWidget);
    expect(find.byIcon(AppIcons.accountCircle), findsNothing);
  });

  testWidgets('a signed-in member whose profile never loaded stays anonymous', (
    tester,
  ) async {
    resetPreferences();
    final server = FakeProfileServer()..failReads = true;
    final auth = await signedInAuth(server);
    final profile = await loadedProfile(server, auth);

    await _pumpHome(tester, profile: profile, auth: auth);

    // Holding a token is not the same as knowing who you are; the sample
    // member must not stand in for them.
    expect(find.byIcon(AppIcons.accountCircle), findsOneWidget);
  });

  testWidgets('uploading a photo updates the header without a restart', (
    tester,
  ) async {
    resetPreferences();
    final server = FakeProfileServer();
    final auth = await signedInAuth(server);
    final profile = await loadedProfile(server, auth);

    await _pumpHome(tester, profile: profile, auth: auth);
    expect(_bundledAvatar, findsOneWidget);

    server.uploadedAvatar = 'https://cdn.test/avatars/new.jpg';
    await profile.load();
    await tester.pumpAndSettle();

    // The header reads the profile scope, so it follows the change.
    expect(_networkImage('https://cdn.test/avatars/new.jpg'), findsOneWidget);
  });
}
