import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/main.dart';

void main() {
  testWidgets('the app asks the system for portrait only', (tester) async {
    final asked = <List<String>>[];

    // SystemChrome talks over a platform channel; a test listens to it.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          asked.add(List<String>.from(call.arguments as List));
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    lockToPortrait();
    await tester.pump();

    expect(asked, [
      ['DeviceOrientation.portraitUp'],
    ]);
  });

  // The Flutter call only binds once Flutter is running. What stops the
  // window rotating in the moment before that is the native declaration, and
  // losing it would go unnoticed until somebody turned a phone.
  group('the native side agrees', () {
    test('Android pins the activity to portrait', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

      expect(manifest, contains('android:screenOrientation="portrait"'));
    });

    test('iOS offers no landscape, on phone or iPad', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();

      expect(plist, contains('UIInterfaceOrientationPortrait'));
      expect(plist, isNot(contains('UIInterfaceOrientationLandscapeLeft')));
      expect(plist, isNot(contains('UIInterfaceOrientationLandscapeRight')));
    });
  });
}
