import 'package:flutter/material.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:bandar_games/data/mock_data.dart';
import 'package:bandar_games/state/auth_scope.dart';
import 'package:bandar_games/state/chat_scope.dart';
import 'package:bandar_games/state/play_history.dart';
import 'package:bandar_games/state/profile_scope.dart';
import 'package:bandar_games/theme/app_theme.dart';

/// Wraps a screen in the scopes the app provides at its root.
///
/// Screens assert on their scopes rather than tolerating a missing one, so a
/// wiring mistake in the real app is loud instead of silent — which means
/// tests have to supply them too.
Widget wrapScreen(
  Widget child, {
  PlayHistory? history,
  Auth? auth,
  ProfileController? profile,
}) {
  // Never touch the device's real preferences from a test.
  SharedPreferencesAsyncPlatform.instance ??=
      InMemorySharedPreferencesAsync.empty();

  return ProfileScope(
    notifier: profile ?? ProfileController(defaultProfile),
    child: ChatScope(
      notifier: ChatController(),
      child: PlayHistoryScope(
        notifier: history ?? PlayHistory(),
        child: AuthScope(
          notifier: auth ?? Auth(),
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(body: child),
          ),
        ),
      ),
    ),
  );
}
