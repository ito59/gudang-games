import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/services/notification_settings.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/push_scope.dart';

import 'support/fake_notifications.dart';
import 'support/fake_push.dart';
import 'support/preferences.dart';

PushRegistrar _registrar(
  FakeNotificationServer server,
  FakePushMessaging messaging,
  Auth auth,
) => PushRegistrar(
  messaging: messaging,
  repository: () => NotificationRepository(auth: auth, client: server.client),
  auth: auth,
);

void main() {
  test('signing in registers this install', () async {
    resetPreferences();
    final server = FakeNotificationServer();
    final messaging = FakePushMessaging();
    final auth = Auth(client: server.client);
    _registrar(server, messaging, auth);

    await auth.signIn(email: 'a@b.c', password: 'x');
    // The registrar reacts to the session, not to a screen being opened.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(server.devices, hasLength(1));
    expect(server.devices.first['method'], 'POST');
    expect(server.devices.first['token'], 'device-token');
  });

  test('news on subscribes the topic, off unsubscribes it', () async {
    resetPreferences();
    final server = FakeNotificationServer(news: true);
    final messaging = FakePushMessaging();
    final auth = Auth(client: server.client);
    await auth.signIn(email: 'a@b.c', password: 'x');
    final push = _registrar(server, messaging, auth);

    await push.register();
    expect(messaging.subscribed, ['news']);

    await push.applyNewsPreference(on: false, topic: 'news');
    expect(messaging.unsubscribed, ['news']);
  });

  test('declining the permission registers nothing', () async {
    resetPreferences();
    final server = FakeNotificationServer();
    // Null token: they said no, or this build has no Firebase.
    final messaging = FakePushMessaging(token: null);
    final auth = Auth(client: server.client);
    await auth.signIn(email: 'a@b.c', password: 'x');

    await _registrar(server, messaging, auth).register();

    expect(server.devices, isEmpty);
    expect(messaging.subscribed, isEmpty);
  });

  test('signing out forgets this install', () async {
    resetPreferences();
    final server = FakeNotificationServer();
    final messaging = FakePushMessaging();
    final auth = Auth(client: server.client);
    await auth.signIn(email: 'a@b.c', password: 'x');
    final push = _registrar(server, messaging, auth);
    await push.register();

    server.devices.clear();
    await auth.signOut();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    // The next person to pick up this phone must not be sent the last
    // person's messages.
    expect(server.devices.single['method'], 'DELETE');
    expect(server.devices.single['token'], 'device-token');
  });

  test('signed out, nothing is registered at all', () async {
    resetPreferences();
    final server = FakeNotificationServer();
    final messaging = FakePushMessaging();

    await _registrar(server, messaging, Auth(client: server.client)).register();

    expect(messaging.startCount, 0);
    expect(server.devices, isEmpty);
  });
}
