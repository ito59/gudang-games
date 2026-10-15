import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/data/mock_data.dart';
import 'package:bandar_games/screens/profile_screen.dart';
import 'package:bandar_games/screens/sign_in_screen.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/profile_scope.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_profile.dart';
import 'support/preferences.dart';

Future<void> _pump(
  WidgetTester tester,
  Auth auth,
  ProfileController profile,
) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    AuthScope(
      notifier: auth,
      child: ProfileScope(
        notifier: profile,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(resetPreferences);

  testWidgets('signed out, it asks for a sign in rather than showing a mock', (
    tester,
  ) async {
    final server = FakeProfileServer();
    final auth = Auth(client: server.client);

    await _pump(
      tester,
      auth,
      ProfileController(defaultProfile, auth: auth, client: server.client),
    );

    expect(find.text('Not signed in'), findsOneWidget);
    // The bundled placeholder must never be presented as somebody's account.
    expect(find.text('Rey Anandra'), findsNothing);
    expect(find.text('Edit Profile'), findsNothing);

    await tester.tap(find.widgetWithText(InkWell, 'Sign in').first);
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('signed in, it shows what the backend returned', (tester) async {
    final server = FakeProfileServer(
      name: 'Dita Prameswari',
      username: 'ditaprams',
      bio: 'Raid lead.',
      location: 'Surabaya, ID',
    );
    final auth = await signedInAuth(server);

    await _pump(tester, auth, await loadedProfile(server, auth));

    expect(find.text('Dita Prameswari'), findsOneWidget);
    expect(find.text('@ditaprams'), findsOneWidget);
    expect(find.text('Raid lead.'), findsOneWidget);
    expect(find.text('Surabaya, ID'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
  });

  testWidgets('a profile that did not load withholds editing', (tester) async {
    final server = FakeProfileServer(failReads: true);
    final auth = await signedInAuth(server);

    await _pump(tester, auth, await loadedProfile(server, auth));

    expect(find.text('Your profile did not load'), findsOneWidget);
    // Editing placeholder data would write the placeholder to the account.
    expect(find.text('Edit Profile'), findsNothing);
  });

  testWidgets('signing out drops the member from the page', (tester) async {
    final server = FakeProfileServer();
    final auth = await signedInAuth(server);
    final profile = await loadedProfile(server, auth);

    await _pump(tester, auth, profile);
    expect(find.text('Sinta Maharani'), findsOneWidget);

    await auth.signOut();
    await tester.pumpAndSettle();

    expect(find.text('Sinta Maharani'), findsNothing);
    expect(find.text('Not signed in'), findsOneWidget);

    // The screen hiding it is not enough: the controller must stop holding
    // the member, or the next person sees them before their own load lands.
    expect(profile.isLive, isFalse);
    expect(profile.profile.name, isNot('Sinta Maharani'));
  });

  testWidgets('the next person never sees the last one', (tester) async {
    final server = FakeProfileServer();
    final auth = await signedInAuth(server);
    final profile = await loadedProfile(server, auth);

    await _pump(tester, auth, profile);
    expect(find.text('Sinta Maharani'), findsOneWidget);

    await auth.signOut();
    await tester.pumpAndSettle();

    // A different member signs in on the same device.
    server
      ..name = 'Dita Prameswari'
      ..username = 'ditaprams';
    await auth.signIn(email: 'dita@test', password: 'password');
    await tester.pumpAndSettle();

    expect(find.text('Dita Prameswari'), findsOneWidget);
    expect(find.text('Sinta Maharani'), findsNothing);
    expect(find.text('@sintam'), findsNothing);
  });

  group('ProfileController', () {
    test('it loads the signed-in member', () async {
      resetPreferences();
      final server = FakeProfileServer();
      final auth = await signedInAuth(server);
      final controller = await loadedProfile(server, auth);

      expect(controller.isLive, isTrue);
      expect(controller.profile.username, 'sintam');
      expect(controller.profile.gamesOwned, 42);
    });

    test('it stays not-live when the read fails', () async {
      resetPreferences();
      final server = FakeProfileServer(failReads: true);
      final auth = await signedInAuth(server);
      final controller = await loadedProfile(server, auth);

      expect(controller.isLive, isFalse);
    });

    test('a Google photo is preferred over the bundled art', () async {
      resetPreferences();
      final server = FakeProfileServer(
        googleAvatar: 'https://lh3.googleusercontent.com/a/photo',
      );
      final auth = await signedInAuth(server);
      final controller = await loadedProfile(server, auth);

      expect(
        controller.profile.avatarUrl,
        'https://lh3.googleusercontent.com/a/photo',
      );
    });

    test('signing in loads the profile without being asked', () async {
      resetPreferences();
      final server = FakeProfileServer();
      final auth = Auth(client: server.client);
      final controller = ProfileController(
        defaultProfile,
        auth: auth,
        client: server.client,
      );

      expect(controller.isLive, isFalse);

      await auth.signIn(email: 'a@b.c', password: 'password');
      // The controller follows the session rather than needing a caller to
      // remember to reload it.
      await Future<void>.delayed(Duration.zero);

      expect(controller.isLive, isTrue);
      expect(controller.profile.username, 'sintam');
    });
  });
}
