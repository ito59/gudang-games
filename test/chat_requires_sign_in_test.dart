import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/screens/chat_screen.dart';
import 'package:bandar_games/screens/community_screen.dart';
import 'package:bandar_games/screens/messages_screen.dart';
import 'package:bandar_games/screens/sign_in_screen.dart';
import 'package:bandar_games/services/chat_repository.dart';
import 'package:bandar_games/services/feed_repository.dart';
import 'package:bandar_games/services/member_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_chat.dart';
import 'support/fake_feed.dart';
import 'support/preferences.dart';

/// Pumps [screen] behind a button, so the test can open it the way the app
/// does — pushed onto a route somebody can be sent back to.
Future<void> _open(
  WidgetTester tester,
  Widget screen, {
  required Auth auth,
  required FakeChatServer server,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ChatScope(
      notifier: ChatController(
        repository: ChatRepository(auth: auth, client: server.client),
        realtime: FakeRealtime(),
        auth: auth,
      ),
      child: AuthScope(
        notifier: auth,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => screen),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// The Community page with every server behind a fake and nobody signed in.
Future<FakeChatServer> _pumpCommunitySignedOut(WidgetTester tester) async {
  resetPreferences();
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final feed = FakeFeedServer();
  final chat = FakeChatServer();
  final auth = Auth(client: feed.client);

  await tester.pumpWidget(
    ChatScope(
      notifier: ChatController(
        repository: ChatRepository(auth: auth, client: chat.client),
        realtime: FakeRealtime(),
        auth: auth,
      ),
      child: AuthScope(
        notifier: auth,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CommunityScreen(
              repository: FeedRepository(auth: auth, client: feed.client),
              members: MemberRepository(auth: auth, client: feed.client),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return chat;
}

void main() {
  group('every way into a chat', () {
    testWidgets('the Online now strip asks for a sign-in', (tester) async {
      final chat = await _pumpCommunitySignedOut(tester);

      await tester.tap(find.text('Dita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Message'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      // Not a request that would earn a 401 and end a session that was
      // never there, and not a snackbar blaming the server.
      expect(chat.calls, isNot(contains('POST /api/v1/conversations')));
      expect(find.text('Could not open that chat.'), findsNothing);
    });

    testWidgets('a member profile asks too', (tester) async {
      final chat = await _pumpCommunitySignedOut(tester);

      await tester.tap(find.text('Dita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Message'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(chat.calls, isNot(contains('POST /api/v1/conversations')));
    });

    testWidgets('the Messages button in the header asks too', (tester) async {
      await _pumpCommunitySignedOut(tester);

      await tester.tap(find.byTooltip('Messages'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  testWidgets('the messages list sends a signed-out visitor to sign in', (
    tester,
  ) async {
    resetPreferences();
    final server = FakeChatServer();

    await _open(tester, const MessagesScreen(),
        auth: Auth(client: server.client), server: server);

    // Not an empty list, which would read as "you have no messages" when the
    // truth is "we do not know who you are".
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.textContaining('No messages yet'), findsNothing);
  });

  testWidgets('a thread does too', (tester) async {
    resetPreferences();
    final server = FakeChatServer();

    await _open(tester, const ChatScreen(conversationId: '1'),
        auth: Auth(client: server.client), server: server);

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('declining takes them back where they came from', (tester) async {
    resetPreferences();
    final server = FakeChatServer();

    await _open(tester, const MessagesScreen(),
        auth: Auth(client: server.client), server: server);
    expect(find.byType(SignInScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Neither the sign-in page nor a chat page they cannot use.
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(MessagesScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('a signed-in member is left alone', (tester) async {
    resetPreferences();
    final server = FakeChatServer()..seedThread(memberId: 2, name: 'Dita');
    final auth = Auth(client: server.client);
    await auth.signIn(email: 'a@b.c', password: 'x');

    await _open(tester, const MessagesScreen(), auth: auth, server: server);

    expect(find.byType(SignInScreen), findsNothing);
    expect(find.text('Dita'), findsOneWidget);
  });

  testWidgets('a session ending while the list is open asks to sign in again', (
    tester,
  ) async {
    resetPreferences();
    final server = FakeChatServer()..seedThread(memberId: 2, name: 'Dita');
    final auth = Auth(client: server.client);
    await auth.signIn(email: 'a@b.c', password: 'x');

    await _open(tester, const MessagesScreen(), auth: auth, server: server);
    expect(find.byType(SignInScreen), findsNothing);

    // What a refused token now does.
    await auth.signOut();
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
