import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Gives the current test its own preferences.
///
/// The in-memory backend registered for the file is shared by every test in
/// it, so a session persisted by one test is still there for the next one —
/// which quietly turns "signed out" assertions green for the wrong reason.
void resetPreferences() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
}
