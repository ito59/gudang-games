import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/screens/notifications_screen.dart';
import 'package:bandar_games/screens/profile_screen.dart';
import 'package:bandar_games/screens/sign_in_screen.dart';
import 'package:bandar_games/services/notification_settings.dart';
import 'package:bandar_games/state/auth_scope.dart';

import 'support/fake_notifications.dart';
import 'support/fake_profile.dart';
import 'support/preferences.dart';
import 'support/scopes.dart';

Future<Auth> _signedIn(FakeNotificationServer server) async {
  resetPreferences();
  final auth = Auth(client: server.client);
  expect(await auth.signIn(email: 'a@b.c', password: 'x'), isNull);
  return auth;
}

Future<void> _pump(
  WidgetTester tester,
  FakeNotificationServer server, {
  Auth? auth,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    wrapScreen(
      NotificationsScreen(
        repository: NotificationRepository(
          auth: auth ?? await _signedIn(server),
          client: server.client,
        ),
      ),
      auth: auth ?? await _signedIn(server),
    ),
  );
  await tester.pumpAndSettle();
}

SwitchListTile _switchFor(WidgetTester tester, String label) =>
    tester.widget<SwitchListTile>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(SwitchListTile),
      ),
    );

void main() {
  testWidgets('both are on for somebody who has never changed them', (
    tester,
  ) async {
    final server = FakeNotificationServer();
    final auth = await _signedIn(server);

    await _pump(tester, server, auth: auth);

    expect(_switchFor(tester, 'Messages').value, isTrue);
    expect(_switchFor(tester, 'News from the team').value, isTrue);
  });

  testWidgets('turning one off saves it and leaves the other alone', (
    tester,
  ) async {
    final server = FakeNotificationServer();
    final auth = await _signedIn(server);

    await _pump(tester, server, auth: auth);
    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();

    expect(server.calls, contains('PATCH /api/v1/me/notifications'));
    expect(server.chat, isFalse);
    // One switch must not carry the other with it.
    expect(server.news, isTrue);
    expect(_switchFor(tester, 'News from the team').value, isTrue);
  });

  testWidgets('a setting that did not save goes back', (tester) async {
    final server = FakeNotificationServer()..failSaves = true;
    final auth = await _signedIn(server);

    await _pump(tester, server, auth: auth);
    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();

    // Better a switch that admits it than one showing a preference the
    // server never received.
    expect(_switchFor(tester, 'Messages').value, isTrue);
    expect(find.text('That setting did not save.'), findsOneWidget);
  });

  testWidgets('a server that cannot deliver says so', (tester) async {
    final server = FakeNotificationServer(pushAvailable: false);
    final auth = await _signedIn(server);

    await _pump(tester, server, auth: auth);

    expect(find.textContaining('cannot send notifications yet'), findsOneWidget);
  });

  testWidgets('a server that can deliver says nothing extra', (tester) async {
    final server = FakeNotificationServer(pushAvailable: true);
    final auth = await _signedIn(server);

    await _pump(tester, server, auth: auth);

    expect(find.textContaining('cannot send notifications yet'), findsNothing);
  });

  testWidgets('signed out, it asks for a sign-in', (tester) async {
    resetPreferences();
    final server = FakeNotificationServer();

    await tester.pumpWidget(
      wrapScreen(
        NotificationsScreen(
          repository: NotificationRepository(
            auth: Auth(client: server.client),
            client: server.client,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('Profile opens it from the Notifications row', (tester) async {
    resetPreferences();
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final profileServer = FakeProfileServer();
    final auth = await signedInAuth(profileServer);
    final profile = await loadedProfile(profileServer, auth);

    await tester.pumpWidget(
      wrapScreen(const ProfileScreen(), auth: auth, profile: profile),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsScreen), findsOneWidget);
  });
}
