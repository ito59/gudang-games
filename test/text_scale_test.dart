import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bandar_games/main.dart';
import 'package:bandar_games/screens/chat_screen.dart';
import 'package:bandar_games/screens/edit_profile_screen.dart';
import 'package:bandar_games/screens/member_profile_screen.dart';
import 'package:bandar_games/screens/messages_screen.dart';
import 'package:bandar_games/services/chat_repository.dart';
import 'package:bandar_games/services/feed_repository.dart';
import 'package:bandar_games/services/member_repository.dart';

import 'support/fake_chat.dart';
import 'support/fake_feed.dart';
import 'support/fake_games.dart';
import 'support/fake_profile.dart';
import 'support/preferences.dart';

/// Overflow shows up as a `FlutterError`, not a thrown exception, so it has to
/// be captured from the error handler.
///
/// A 4px game-card overflow was reported from a device whose font size was set
/// to about 110%; the grid extent had been hard-coded to the exact sum of its
/// children, leaving no room for scaled text.
void main() {
  for (final scale in [1.0, 1.1, 1.3, 1.5, 2.0]) {
    testWidgets('no overflow at text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      resetPreferences();
      // The profile tab shows a sign-in prompt without a session, so the
      // screens this sweeps for overflow would never be laid out.
      final server = FakeProfileServer();
      final auth = await signedInAuth(server);
      final profile = await loadedProfile(server, auth);
      // The community page reads its feed and members from the API, and the
      // messages list reads its threads.
      final feed = FakeFeedServer();
      final chat = FakeChatServer();
      final thread = chat.seedThread(memberId: 2, name: 'Dita Prameswari');
      chat.seedMessage(thread, 'Running it again tonight?', authorId: 2);

      final overflows = <String>{};
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed')) {
          final where = RegExp(r'\w+\.dart:\d+')
              .allMatches(details.toString())
              .map((match) => match.group(0))
              .toSet()
              .join(', ');
          overflows.add('${message.split('\n').first} [$where]');
        } else {
          previous?.call(details);
        }
      };
      addTearDown(() => FlutterError.onError = previous);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: BandarGamesApp(
            gameRepository: fakeGameRepository(),
            feedRepository: FeedRepository(auth: auth, client: feed.client),
            memberRepository: MemberRepository(auth: auth, client: feed.client),
            chatRepository: ChatRepository(auth: auth, client: chat.client),
            realtime: FakeRealtime(),
            auth: auth,
            profileController: profile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Walk every destination, the chat surfaces, then the pushed editor.
      for (final tab in ['Library', 'Community']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
      }

      // The member sheet and another player's profile.
      await tester.tap(find.text('Dita'));
      await tester.pumpAndSettle();
      expect(find.text('View profile'), findsOneWidget);

      await tester.tap(find.text('View profile'));
      await tester.pumpAndSettle();
      expect(find.byType(MemberProfileScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Messages'));
      await tester.pumpAndSettle();
      expect(find.byType(MessagesScreen), findsOneWidget);

      await tester.tap(find.text('Dita Prameswari'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      // At large scales the button sits below the fold, so scroll it into
      // view first — a missed tap would leave the editor unopened and make
      // the rest of this test vacuous.
      await tester.ensureVisible(find.text('Edit Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);

      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });
  }
}
