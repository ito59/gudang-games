import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/screens/chat_screen.dart';
import 'package:bandar_games/screens/messages_screen.dart';
import 'package:bandar_games/services/chat_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_chat.dart';
import 'support/fonts.dart';
import 'support/images.dart';
import 'support/preferences.dart';

/// Bubbles print an absolute clock time, so seeding from `DateTime.now()`
/// makes the chat golden depend on when it was generated. The times of day
/// are pinned and the dates kept relative, so the Today/Yesterday separators
/// still render without the clock drifting the image.
DateTime _at(int daysAgo, int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: daysAgo))
      .add(Duration(hours: hour, minutes: minute));
}

/// The list prints a *relative* time instead, so it needs the opposite: fixed
/// offsets from now, which read the same whenever the test runs.
DateTime _ago(Duration since) => DateTime.now().subtract(since);

/// The threads the messages list was drawn around.
FakeChatServer _listServer() {
  final server = FakeChatServer();

  final dita = server.seedThread(
    memberId: 2,
    name: 'Dita Prameswari',
    handle: 'ditaprams',
    unread: 2,
  );
  server.seedMessage(
    dita,
    'I can bring a healer if you need one.',
    authorId: 2,
    at: _ago(const Duration(minutes: 5)),
  );

  // They have read as far as my reply, so its tick is the blue double one.
  // Set rather than assumed: the app no longer invents a read receipt.
  server.conversations
      .firstWhere((c) => c['id'] == dita)['their_last_read_id'] = 2;

  final bagas = server.seedThread(
    memberId: 3,
    name: 'Bagas Wirawan',
    handle: 'bagaswir',
    accent: '#FFB2BA',
  );
  server.seedMessage(
    bagas,
    'Time trial squad still needs one. You in?',
    authorId: 3,
    at: _ago(const Duration(hours: 2)),
  );

  final salsa = server.seedThread(
    memberId: 4,
    name: 'Salsa Nurhaliza',
    handle: 'salsanh',
    accent: '#4ADE80',
    unread: 1,
  );
  server.seedMessage(
    salsa,
    'Patch notes are up, the support tree got reworked.',
    authorId: 4,
    at: _ago(const Duration(days: 1)),
  );

  return server;
}

/// The thread the chat screen was drawn around.
FakeChatServer _server() {
  final server = FakeChatServer();

  final dita = server.seedThread(
    memberId: 2,
    name: 'Dita Prameswari',
    handle: 'ditaprams',
    unread: 2,
  );
  server.seedMessage(
    dita,
    'That raid clip is still doing numbers, nice one.',
    authorId: 2,
    at: _at(1, 9, 48),
  );
  server.seedMessage(
    dita,
    'Thanks! The west bridge hold did all the work.',
    authorId: 1,
    at: _at(1, 9, 58),
  );
  server.seedMessage(
    dita,
    'Running it again tonight?',
    authorId: 2,
    at: _at(0, 12, 6),
  );
  server.seedMessage(
    dita,
    'I can bring a healer if you need one.',
    authorId: 2,
    at: _at(0, 12, 8),
  );

  final bagas = server.seedThread(
    memberId: 3,
    name: 'Bagas Wirawan',
    handle: 'bagaswir',
    accent: '#FFB2BA',
  );
  server.seedMessage(
    bagas,
    'Time trial squad still needs one. You in?',
    authorId: 3,
    at: _at(0, 10, 22),
  );

  final salsa = server.seedThread(
    memberId: 4,
    name: 'Salsa Nurhaliza',
    handle: 'salsanh',
    accent: '#4ADE80',
    unread: 1,
  );
  server.seedMessage(
    salsa,
    'Patch notes are up, the support tree got reworked.',
    authorId: 4,
    at: _at(2, 20, 15),
  );

  return server;
}

/// The session [_loaded] last built, which the screens read.
late Auth auth;

Future<ChatController> _loaded(FakeChatServer server, {String? thread}) async {
  resetPreferences();
  auth = Auth(client: server.client);
  await auth.signIn(email: 'a@b.c', password: 'x');

  final chat = ChatController(
    repository: ChatRepository(auth: auth, client: server.client),
    realtime: FakeRealtime(),
    auth: auth,
  );
  await chat.load();
  if (thread != null) await chat.loadThread(thread);

  return chat;
}

Widget _wrap(ChatController chat, Auth auth, Widget child) {
  return ChatScope(
    notifier: chat,
    child: AuthScope(
      notifier: auth,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: child,
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  testWidgets('messages golden', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final chat = await _loaded(_listServer());
    await tester.pumpWidget(_wrap(chat, auth, const MessagesScreen()));
    await tester.pumpAndSettle();
    await precacheAllImages(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/messages.png'),
    );
  });

  testWidgets('chat golden', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final chat = await _loaded(_server(), thread: '1');
    await tester.pumpWidget(_wrap(chat, auth, const ChatScreen(conversationId: '1')));
    await tester.pumpAndSettle();
    await precacheAllImages(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/chat.png'),
    );
  });
}
