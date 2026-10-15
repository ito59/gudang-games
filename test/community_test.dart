import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:bandar_games/screens/article_screen.dart';
import 'package:bandar_games/screens/chat_screen.dart';
import 'package:bandar_games/screens/community_screen.dart';
import 'package:bandar_games/screens/member_profile_screen.dart';
import 'package:bandar_games/screens/sign_in_screen.dart';
import 'package:bandar_games/services/chat_repository.dart';
import 'package:bandar_games/services/feed_repository.dart';
import 'package:bandar_games/services/member_repository.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';
import 'package:bandar_games/theme/app_icons.dart';
import 'package:bandar_games/theme/app_theme.dart';

import 'support/fake_chat.dart';
import 'support/fake_feed.dart';

/// Pumps the screen against [server]. When [signedIn] the token is already
/// held, matching a member who signed in on a previous run.
/// Set by [_pumpCommunity] so a test can assert what chat was asked for.
late FakeChatServer chatServer;

Future<Auth> _pumpCommunity(
  WidgetTester tester,
  FakeFeedServer server, {
  bool signedIn = true,
}) async {
  chatServer = FakeChatServer();
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = Auth(client: server.client);
  if (signedIn) {
    final error = await auth.signIn(email: 'you@test', password: 'secret');
    expect(error, isNull);
  }

  await tester.pumpWidget(
    ChatScope(
      // The header reads the unread count, and Message opens a thread.
      notifier: ChatController(
        repository: ChatRepository(auth: auth, client: chatServer.client),
        realtime: FakeRealtime(),
        auth: auth,
      ),
      child: AuthScope(
        notifier: auth,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CommunityScreen(
              repository: FeedRepository(auth: auth, client: server.client),
              members: MemberRepository(auth: auth, client: server.client),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

/// A card action by its semantic label. Not `bySemanticsLabel`: these wrap a
/// count, so the merged node reads "Like 248" rather than "Like".
Finder _action(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

/// The heart on a post the member has already liked.
final _unlikeButtons = _action('Unlike');

void main() {
  testWidgets('shows the online strip and the feed from the API', (
    tester,
  ) async {
    final server = FakeFeedServer();
    await _pumpCommunity(tester, server);

    expect(find.text('Online now'), findsOneWidget);
    expect(find.text('Dita'), findsOneWidget);
    expect(find.text('Dita Prameswari'), findsOneWidget);
    expect(find.text('Bagas Wirawan'), findsOneWidget);
    expect(server.calls, contains('GET /api/v1/feed'));
  });

  testWidgets('filter chips narrow the feed', (tester) async {
    await _pumpCommunity(tester, FakeFeedServer());

    await tester.tap(find.text('Squads'));
    await tester.pumpAndSettle();

    expect(find.text('Bagas Wirawan'), findsOneWidget);
    expect(find.text('Dita Prameswari'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('Dita Prameswari'), findsOneWidget);
  });

  testWidgets('liking a post writes to the server and toggles back', (
    tester,
  ) async {
    final server = FakeFeedServer();
    await _pumpCommunity(tester, server);

    expect(find.text('248'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.favorite).first);
    await tester.pumpAndSettle();
    expect(find.text('249'), findsOneWidget);
    expect(server.calls, contains('POST /api/v1/feed/1/like'));

    await tester.tap(find.byIcon(AppIcons.favorite).first);
    await tester.pumpAndSettle();
    expect(find.text('248'), findsOneWidget);
    expect(server.calls, contains('DELETE /api/v1/feed/1/like'));
  });

  testWidgets('likes made on an earlier run come back filled in', (
    tester,
  ) async {
    final server = FakeFeedServer()..likedByMe.add('1');

    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          Auth.tokenKey: 'test-token',
          Auth.userKey: jsonEncode({'id': 1, 'name': 'You', 'handle': 'you'}),
        });

    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = Auth(client: server.client);

    await tester.pumpWidget(
      ChatScope(
        notifier: ChatController(),
        child: AuthScope(
          notifier: auth,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: CommunityScreen(
                repository: FeedRepository(auth: auth, client: server.client),
                members: MemberRepository(auth: auth, client: server.client),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The stored session is restored after the first frame, so the feed the
    // screen already has was answered for nobody.
    expect(_unlikeButtons, findsNothing);

    await auth.load();
    await tester.pumpAndSettle();

    // Knowing who is looking has to send the app back for an answer meant
    // for them, or every like ever made reads as lost.
    expect(server.calls.where((call) => call == 'GET /api/v1/feed').length, 2);
    expect(_unlikeButtons, findsOneWidget);
  });

  testWidgets('an admin announcement reads as news, not as a post', (
    tester,
  ) async {
    final server = FakeFeedServer()..seedNews();
    await _pumpCommunity(tester, server);

    expect(find.text('NEWS'), findsOneWidget);
    expect(find.text('Season 2 lands next week'), findsOneWidget);
    // The card is a summary; the rest of the article waits for the tap.
    expect(find.text('New maps come with it.'), findsNothing);
  });

  testWidgets('an announcement opens full page and reads whole', (
    tester,
  ) async {
    final server = FakeFeedServer()..seedNews();
    await _pumpCommunity(tester, server);

    await tester.tap(find.text('Season 2 lands next week'));
    await tester.pumpAndSettle();

    expect(find.byType(ArticleScreen), findsOneWidget);
    // Blank lines in the dashboard become paragraphs here.
    expect(find.text('Ranked resets on Monday.'), findsOneWidget);
    expect(find.text('New maps come with it.'), findsOneWidget);
  });

  testWidgets('a like from the article follows back to the feed', (
    tester,
  ) async {
    final server = FakeFeedServer()..seedNews();
    await _pumpCommunity(tester, server);

    await tester.tap(find.text('Season 2 lands next week'));
    await tester.pumpAndSettle();

    await tester.tap(_action('Like'));
    await tester.pumpAndSettle();
    expect(server.calls, contains('POST /api/v1/feed/9/like'));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // The card behind the article must not still say 12.
    expect(find.text('13'), findsOneWidget);
  });

  testWidgets('the composer does not offer News', (tester) async {
    await _pumpCommunity(tester, FakeFeedServer());

    await tester.tap(find.byTooltip('New post'));
    await tester.pumpAndSettle();

    // News speaks for the team and is written in the dashboard, so the kind
    // is missing from the composer even though the feed can filter by it.
    final composer = find.byType(BottomSheet);
    expect(
      find.descendant(of: composer, matching: find.text('Updates')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: composer, matching: find.text('News')),
      findsNothing,
    );
  });

  testWidgets('a like the server rejects is rolled back', (tester) async {
    final server = FakeFeedServer(failLike: true);
    await _pumpCommunity(tester, server);

    await tester.tap(find.byIcon(AppIcons.favorite).first);
    await tester.pumpAndSettle();

    // The count must not keep a like the server never recorded.
    expect(find.text('248'), findsOneWidget);
    expect(find.text('That like did not save.'), findsOneWidget);
  });

  testWidgets('a like survives filtering', (tester) async {
    await _pumpCommunity(tester, FakeFeedServer());

    await tester.tap(find.byIcon(AppIcons.favorite).first);
    await tester.pumpAndSettle();
    expect(find.text('249'), findsOneWidget);

    await tester.tap(find.text('Squads'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clips'));
    await tester.pumpAndSettle();

    expect(find.text('249'), findsOneWidget);
  });

  testWidgets('writing a post puts it at the top of the feed', (tester) async {
    final server = FakeFeedServer();
    await _pumpCommunity(tester, server);

    await tester.tap(find.byTooltip('New post'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'First run cleared.');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(server.calls, contains('POST /api/v1/feed'));
    expect(find.text('First run cleared.'), findsOneWidget);
    expect(server.posts.first['body'], 'First run cleared.');
  });

  testWidgets('a post that the active filter hides still shows', (
    tester,
  ) async {
    final server = FakeFeedServer();
    await _pumpCommunity(tester, server);

    await tester.tap(find.text('Squads'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New post'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Patch notes are out.');
    await tester.pumpAndSettle();
    // The composer defaults to Updates, which the Squads filter excludes.
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(server.posts.first['body'], 'Patch notes are out.');
    expect(find.byType(TextField), findsNothing, reason: 'composer closed');
    expect(find.text('Patch notes are out.'), findsOneWidget);
    // Clearing the filter is what makes it visible at all.
    expect(find.text('Bagas Wirawan'), findsOneWidget);
  });

  testWidgets('comments open, read and post back', (tester) async {
    final server = FakeFeedServer();
    await _pumpCommunity(tester, server);

    await tester.tap(find.byIcon(AppIcons.modeComment).first);
    await tester.pumpAndSettle();

    expect(find.text('That last hit was clean.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Nice run.');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(server.calls, contains('POST /api/v1/feed/1/comments'));
    expect(find.text('Nice run.'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    // The card's count goes up by what was written, from 12 to 13.
    expect(find.text('13'), findsOneWidget);
    expect(find.text('12'), findsNothing);
  });

  testWidgets('closing a thread does not shrink the comment count', (
    tester,
  ) async {
    // The post claims 12 comments; one page of the thread holds 1. Writing
    // the page length back would silently drop the other 11.
    await _pumpCommunity(tester, FakeFeedServer());

    await tester.tap(find.byIcon(AppIcons.modeComment).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('signed out, writing asks for a sign in first', (tester) async {
    final server = FakeFeedServer();
    await _pumpCommunity(tester, server, signedIn: false);

    await tester.tap(find.byIcon(AppIcons.favorite).first);
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    // Nothing was sent on behalf of a member who is not signed in.
    expect(server.calls, isNot(contains('POST /api/v1/feed/1/like')));
  });

  testWidgets('signing in from the prompt returns to the feed', (
    tester,
  ) async {
    final server = FakeFeedServer();
    await _pumpCommunity(tester, server, signedIn: false);

    await tester.tap(find.byTooltip('New post'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'you@test');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsNothing);
    // The composer the sign-in interrupted is now open.
    expect(find.text('New post'), findsWidgets);
  });

  testWidgets('a feed that fails to load says so and can retry', (
    tester,
  ) async {
    final server = FakeFeedServer(failFeed: true);
    await _pumpCommunity(tester, server);

    expect(find.text('The feed did not load'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsNothing);

    server.failFeed = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Dita Prameswari'), findsOneWidget);
  });

  testWidgets('tapping a member offers profile and message', (tester) async {
    await _pumpCommunity(tester, FakeFeedServer());

    await tester.tap(find.text('Dita'));
    await tester.pumpAndSettle();

    // The tap must not assume the user wanted a chat.
    expect(find.byType(ChatScreen), findsNothing);
    expect(find.text('View profile'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Playing Mystic Ruin'), findsOneWidget);
  });

  testWidgets('choosing Message opens the thread', (tester) async {
    await _pumpCommunity(tester, FakeFeedServer());

    await tester.tap(find.text('Dita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();

    expect(chatServer.calls, contains('POST /api/v1/conversations'));
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('choosing View profile opens the member page', (tester) async {
    await _pumpCommunity(tester, FakeFeedServer());

    await tester.tap(find.text('Dita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View profile'));
    await tester.pumpAndSettle();

    expect(find.byType(MemberProfileScreen), findsOneWidget);
    expect(find.text('@ditaprams'), findsOneWidget);
    expect(find.text('980'), findsOneWidget);
  });

  testWidgets('tapping a post author opens their profile', (tester) async {
    await _pumpCommunity(tester, FakeFeedServer());

    await tester.tap(find.text('Bagas Wirawan'));
    await tester.pumpAndSettle();

    // The name already says which of the two things the tap wanted, so it
    // goes straight there rather than asking again.
    expect(find.byType(MemberProfileScreen), findsOneWidget);
    expect(find.text('@bagaswir'), findsOneWidget);
  });

  testWidgets('a member profile shows that member and only their posts', (
    tester,
  ) async {
    final server = FakeFeedServer();
    await _pumpCommunity(tester, server);

    await tester.tap(find.text('Dita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View profile'));
    await tester.pumpAndSettle();

    expect(server.calls, contains('GET /api/v1/members/2'));
    expect(find.text('Posts'), findsOneWidget);
    expect(
      find.text('Cleared the Mystic Ruin raid on the first try.'),
      findsOneWidget,
    );
    // Somebody else's post has no business on this page.
    expect(find.text('Looking for two more for tonight.'), findsNothing);
  });

  testWidgets('liking from a profile writes to the server', (tester) async {
    final server = FakeFeedServer();
    await _pumpCommunity(tester, server);

    await tester.tap(find.text('Dita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View profile'));
    await tester.pumpAndSettle();

    expect(find.text('248'), findsOneWidget);
    await tester.tap(find.byIcon(AppIcons.favorite).first);
    await tester.pumpAndSettle();

    expect(find.text('249'), findsOneWidget);
    expect(server.calls, contains('POST /api/v1/feed/1/like'));
  });

  testWidgets('commenting from a profile posts to that thread', (tester) async {
    final server = FakeFeedServer();
    await _pumpCommunity(tester, server);

    await tester.tap(find.text('Dita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.modeComment).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Nice run.');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(AppIcons.send));
    await tester.pumpAndSettle();

    expect(server.calls, contains('POST /api/v1/feed/1/comments'));
    expect(find.text('Nice run.'), findsOneWidget);
  });

  testWidgets('asking to be friends leaves the request showing', (
    tester,
  ) async {
    final server = FakeFeedServer();
    await _pumpCommunity(tester, server);

    await tester.tap(find.text('Dita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Add friend'));
    await tester.pumpAndSettle();

    expect(server.calls, contains('POST /api/v1/members/2/friend'));
    expect(find.text('Friend request sent to Dita Prameswari.'), findsOneWidget);
    // The button has to hold the new state, or the tap reads as lost.
    expect(find.bySemanticsLabel('Requested — tap to withdraw'), findsOneWidget);
  });

  testWidgets('a request waiting on you is answered in words', (tester) async {
    final server = FakeFeedServer();
    server.members[2]!['friendship'] = 'pending';
    await _pumpCommunity(tester, server);

    // The header says one is waiting.
    await tester.tap(find.byTooltip('Friend requests'));
    await tester.pumpAndSettle();
    expect(find.text('Dita Prameswari'), findsOneWidget);

    await tester.tap(find.byTooltip('Accept Dita Prameswari'));
    await tester.pumpAndSettle();

    expect(server.calls, contains('POST /api/v1/members/2/friend/accept'));
    expect(find.text('You and Dita Prameswari are friends.'), findsOneWidget);
    expect(find.text('Nobody is waiting on you.'), findsOneWidget);
  });
}
