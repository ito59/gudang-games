import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/main.dart';
import 'package:bandar_games/screens/edit_profile_screen.dart';

import 'support/fake_games.dart';
import 'support/fake_profile.dart';
import 'support/preferences.dart';

late FakeProfileServer server;

/// Opens the profile tab with a signed-in member whose data comes from
/// [server] — the page shows a sign-in prompt without one.
Future<void> _openProfile(WidgetTester tester) async {
  // Tall enough that the whole form, including the bottom save button, is
  // laid out — a lazy ListView never builds what is off-screen.
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = await signedInAuth(server);
  final profile = await loadedProfile(server, auth);

  await tester.pumpWidget(
    GudangGamesApp(
      gameRepository: fakeGameRepository(),
      auth: auth,
      profileController: profile,
    ),
  );
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
}

Future<void> _openEditor(WidgetTester tester) async {
  await _openProfile(tester);
  await tester.tap(find.text('Edit Profile'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    resetPreferences();
    server = FakeProfileServer();
  });

  testWidgets('profile tab shows the member from the backend', (tester) async {
    await _openProfile(tester);

    expect(find.text('Sinta Maharani'), findsOneWidget);
    expect(find.text('@sintam'), findsOneWidget);
    expect(find.text('Yogyakarta, ID'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(server.calls, contains('GET /api/v1/me'));

    // The bundled placeholder is a different person on purpose.
    expect(find.text('Rey Anandra'), findsNothing);
  });

  testWidgets('saving an edit updates the profile page', (tester) async {
    await _openEditor(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sinta Maharani'),
      'Sinta M.',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('Sinta M.'), findsOneWidget);
    expect(find.text('Profile updated'), findsOneWidget);

    // The edit has to reach the server, not just the screen.
    expect(server.calls, contains('PATCH /api/v1/me'));
    expect(server.name, 'Sinta M.');
  });

  testWidgets('every editable field is written back', (tester) async {
    await _openEditor(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sinta Maharani'),
      'Sinta M.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'sintam'),
      'sintamaharani',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Yogyakarta, ID'),
      'Bandung, ID',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, server.bio),
      'Back on ranked.',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(server.name, 'Sinta M.');
    expect(server.username, 'sintamaharani');
    expect(server.location, 'Bandung, ID');
    expect(server.bio, 'Back on ranked.');

    expect(find.text('@sintamaharani'), findsOneWidget);
    expect(find.text('Bandung, ID'), findsOneWidget);
    expect(find.text('Back on ranked.'), findsOneWidget);
  });

  testWidgets('a username the server rejects is reported', (tester) async {
    server = FakeProfileServer(takenUsernames: {'taken'});
    await _openEditor(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'sintam'),
      'taken',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    // The server owns this rule, so its wording is what gets shown.
    expect(find.text('That username is taken.'), findsOneWidget);
    expect(find.text('Profile updated'), findsNothing);
    // The page must not show a handle the server refused.
    expect(find.text('@taken'), findsNothing);
    expect(find.text('@sintam'), findsOneWidget);
  });

  testWidgets('a cleared bio is saved as cleared', (tester) async {
    await _openEditor(tester);

    await tester.enterText(find.widgetWithText(TextFormField, server.bio), '');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(server.bio, '');
  });

  testWidgets('an empty display name blocks saving', (tester) async {
    await _openEditor(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sinta Maharani'),
      '   ',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Display name cannot be empty'), findsOneWidget);
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('a too-short username blocks saving', (tester) async {
    await _openEditor(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'sintam'),
      'ab',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Use at least 3 characters'), findsOneWidget);
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('username input rejects spaces and punctuation', (tester) async {
    await _openEditor(tester);

    final field = find.widgetWithText(TextFormField, 'sintam');
    await tester.enterText(field, 'sin tam!');
    await tester.pump();

    expect(find.text('sintam'), findsOneWidget);
  });

  testWidgets('backing out with changes asks before discarding', (
    tester,
  ) async {
    await _openEditor(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sinta Maharani'),
      'Someone Else',
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    // The discarded edit must not have reached the profile.
    expect(find.text('Sinta Maharani'), findsOneWidget);
  });

  testWidgets('backing out without changes leaves immediately', (
    tester,
  ) async {
    await _openEditor(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.byType(EditProfileScreen), findsNothing);
  });
}
