import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/data/mock_data.dart';
import 'package:bandar_games/screens/edit_profile_screen.dart';
import 'package:bandar_games/services/photo_picker.dart';
import 'package:bandar_games/state/profile_scope.dart';
import 'package:bandar_games/theme/app_icons.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_picker.dart';
import 'support/fake_profile.dart';
import 'support/preferences.dart';

/// The first bytes of a JPEG. The picker hands over bytes, so a test needs
/// no file and the upload does no disk work.
PickedPhoto _photo() => PickedPhoto(
  bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
  filename: 'me.jpg',
);

Future<(FakeProfileServer, ProfileController)> _signedIn({
  bool rejectUploads = false,
}) async {
  resetPreferences();
  final server = FakeProfileServer()..rejectUploads = rejectUploads;
  final auth = await signedInAuth(server);
  return (server, await loadedProfile(server, auth));
}

Future<void> _pumpEditor(
  WidgetTester tester,
  ProfileController profile,
  PhotoPicker picker,
) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProfileScope(
      notifier: profile,
      child: MaterialApp(
        theme: AppTheme.light,
        home: EditProfileScreen(profile: profile.profile, picker: picker),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the controller', () {
    test('an uploaded photo becomes the profile photo', () async {
      final (server, profile) = await _signedIn();
      expect(profile.profile.avatarUrl, isNull);

      final error = await profile.setPhoto(_photo());

      expect(error, isNull);
      expect(profile.profile.avatarUrl, 'https://cdn.test/avatars/me.jpg');
      expect(server.calls, contains('POST /api/v1/me/avatar'));
    });

    test('the server owns the wording when it refuses', () async {
      final (_, profile) = await _signedIn(rejectUploads: true);

      final error = await profile.setPhoto(_photo());

      expect(error, 'That photo is larger than 8 MB.');
      expect(profile.profile.avatarUrl, isNull);
    });

    test('removing the photo goes back to initials', () async {
      final (server, profile) = await _signedIn();
      await profile.setPhoto(_photo());

      final error = await profile.removePhoto();

      expect(error, isNull);
      expect(profile.profile.avatarUrl, isNull);
      expect(server.calls, contains('DELETE /api/v1/me/avatar'));
    });

    test('an uploaded photo outranks the one Google had', () async {
      resetPreferences();
      final server = FakeProfileServer(googleAvatar: 'https://google/photo.jpg');
      final auth = await signedInAuth(server);
      final profile = await loadedProfile(server, auth);

      expect(profile.profile.avatarUrl, 'https://google/photo.jpg');

      await profile.setPhoto(_photo());

      // Choosing a photo is deliberate; signing in with Google was not.
      expect(profile.profile.avatarUrl, 'https://cdn.test/avatars/me.jpg');
    });

    test('signed out there is nowhere to send it', () async {
      resetPreferences();
      final controller = ProfileController(defaultProfile);

      expect(await controller.setPhoto(_photo()), 'Please sign in first.');
    });
  });

  group('the editor', () {
    testWidgets('the camera button picks and uploads', (tester) async {
      final (server, profile) = await _signedIn();
      final picker = FakePhotoPicker(photo: _photo());

      await _pumpEditor(tester, profile, picker);
      await tester.tap(find.byIcon(AppIcons.photoCamera));
      await tester.pumpAndSettle();

      expect(picker.pickCount, 1);
      expect(server.calls, contains('POST /api/v1/me/avatar'));
      expect(find.text('Photo updated.'), findsOneWidget);
    });

    testWidgets('backing out of the picker changes nothing', (tester) async {
      final (server, profile) = await _signedIn();
      // Null photo: the member closed the gallery without choosing.
      final picker = FakePhotoPicker();

      await _pumpEditor(tester, profile, picker);
      await tester.tap(find.byIcon(AppIcons.photoCamera));
      await tester.pumpAndSettle();

      expect(picker.pickCount, 1);
      expect(server.calls, isNot(contains('POST /api/v1/me/avatar')));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('with a photo already set, removing it is offered', (
      tester,
    ) async {
      final (server, profile) = await _signedIn();
      await profile.setPhoto(_photo());
      final picker = FakePhotoPicker(photo: _photo());

      await _pumpEditor(tester, profile, picker);
      await tester.tap(find.byIcon(AppIcons.photoCamera));
      await tester.pumpAndSettle();

      // Nothing was picked yet: the tap asked which of the two it was.
      expect(picker.pickCount, 0);
      expect(find.text('Choose a photo'), findsOneWidget);

      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();

      expect(server.calls, contains('DELETE /api/v1/me/avatar'));
      expect(find.text('Photo removed.'), findsOneWidget);
      expect(profile.profile.avatarUrl, isNull);
    });

    testWidgets('a refused upload says why and keeps the old photo', (
      tester,
    ) async {
      final (_, profile) = await _signedIn(rejectUploads: true);
      final picker = FakePhotoPicker(photo: _photo());

      await _pumpEditor(tester, profile, picker);
      await tester.tap(find.byIcon(AppIcons.photoCamera));
      await tester.pumpAndSettle();

      expect(find.text('That photo is larger than 8 MB.'), findsOneWidget);
      expect(profile.profile.avatarUrl, isNull);
    });
  });
}
