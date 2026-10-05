import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Where this install can be reached, and what it is subscribed to.
///
/// Behind a seam because Firebase needs a real device and a platform channel:
/// tests inject their own, the same arrangement [GoogleAuthenticator] and
/// [PhotoPicker] use.
abstract class PushMessaging {
  /// Asks the person's permission and returns this install's token, or null
  /// when they said no, or when this build has no Firebase.
  Future<String?> start();

  Future<void> subscribe(String topic);
  Future<void> unsubscribe(String topic);
}

/// Firebase Cloud Messaging.
class FirebasePushMessaging implements PushMessaging {
  var _started = false;

  @override
  Future<String?> start() async {
    try {
      if (!_started) {
        await Firebase.initializeApp();
        _started = true;
      }

      // iOS refuses to issue a token without this; on Android 13+ it is the
      // runtime notification permission. Declining is an answer, not a fault.
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }

      // On iOS the APNs token arrives slightly after the permission does, and
      // asking too early returns null for a device that is perfectly fine.
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.getAPNSToken();
      }

      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      // No Firebase in this build, or no Play Services on the device. The
      // app works; the phone simply will not buzz.
      return null;
    }
  }

  @override
  Future<void> subscribe(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (_) {
      // Retried the next time the app starts.
    }
  }

  @override
  Future<void> unsubscribe(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (_) {
      // Retried the next time the app starts.
    }
  }
}
