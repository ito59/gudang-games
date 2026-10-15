import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/mock_data.dart';
import 'screens/app_shell.dart';
import 'services/chat_repository.dart';
import 'services/feed_repository.dart';
import 'services/game_repository.dart';
import 'services/google_authenticator.dart';
import 'services/member_repository.dart';
import 'services/report_repository.dart';
import 'services/notification_settings.dart';
import 'services/push_messaging.dart';
import 'services/realtime.dart';
import 'state/auth_scope.dart';
import 'state/chat_scope.dart';
import 'state/play_history.dart';
import 'state/presence.dart';
import 'state/profile_scope.dart';
import 'state/push_scope.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  lockToPortrait();

  // Draw behind the system bars. Without this the Android navigation bar sits
  // there as a solid black band — `SystemUiOverlayStyle.light` hard-codes
  // systemNavigationBarColor to 0xFF000000, which does not match the app's
  // own bottom bar. Android 15+ enforces edge-to-edge anyway.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Dark icons: the header is a light gold band and the page is cream.
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      // Otherwise the platform paints a scrim behind the bar, which reads as
      // a grey band over our own nav panel.
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(const GudangGamesApp());
}

/// Portrait only.
///
/// The layouts are built around a single column — held sideways, the hero
/// slider stretches and the game grid squeezes into something nobody
/// designed.
///
/// Declared natively as well, in `AndroidManifest.xml` and `Info.plist`.
/// This call only takes effect once Flutter is running, which leaves a
/// moment at launch where the system would still rotate the window.
void lockToPortrait() {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

class GudangGamesApp extends StatefulWidget {
  const GudangGamesApp({
    super.key,
    this.gameRepository,
    this.feedRepository,
    this.memberRepository,
    this.reportRepository,
    this.chatRepository,
    this.realtime,
    this.pushMessaging,
    this.auth,
    this.profileController,
  });

  /// Injectable so tests never reach for the network.
  final GameRepository? gameRepository;
  final FeedRepository? feedRepository;
  final MemberRepository? memberRepository;
  final ReportRepository? reportRepository;
  final ChatRepository? chatRepository;
  final Realtime? realtime;
  final PushMessaging? pushMessaging;

  /// Supplied by tests that need a session; built here otherwise. Whatever is
  /// passed in is owned by the caller and not disposed with this widget.
  final Auth? auth;
  final ProfileController? profileController;

  @override
  State<GudangGamesApp> createState() => _GudangGamesAppState();
}

class _GudangGamesAppState extends State<GudangGamesApp> {
  late final _auth =
      widget.auth ?? Auth(google: GoogleSignInAuthenticator());
  late final _profile =
      widget.profileController ?? ProfileController(defaultProfile, auth: _auth);
  late final _realtime =
      widget.realtime ??
      ReverbRealtime(config: _auth.realtimeConfig, auth: _auth);
  late final _chat = ChatController(
    repository: widget.chatRepository ?? ChatRepository(auth: _auth),
    realtime: _realtime,
    auth: _auth,
  );
  final _history = PlayHistory();
  late final _push = PushRegistrar(
    messaging: widget.pushMessaging ?? FirebasePushMessaging(),
    repository: () => NotificationRepository(auth: _auth),
    auth: _auth,
  );
  late final _presence = PresenceTracker(auth: _auth);

  @override
  void initState() {
    super.initState();
    _history.load();
    _presence.start();
    // Restores the session first; the profile follows whoever that is.
    _auth.load().then((_) => _profile.load());
  }

  @override
  void dispose() {
    // Only what this widget created; an injected one outlives it.
    if (widget.profileController == null) _profile.dispose();
    if (widget.auth == null) _auth.dispose();
    _chat.dispose();
    _push.dispose();
    _presence.dispose();
    _history.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PushScope(
      notifier: _push,
      child: ProfileScope(
        notifier: _profile,
        child: ChatScope(
          notifier: _chat,
          child: PlayHistoryScope(
            notifier: _history,
            child: AuthScope(
              notifier: _auth,
              child: MaterialApp(
                title: 'GudangGames',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                home: AppShell(
                  gameRepository: widget.gameRepository,
                  feedRepository: widget.feedRepository,
                  memberRepository: widget.memberRepository,
                  reportRepository: widget.reportRepository,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
