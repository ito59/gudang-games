import 'dart:async';

import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Runs before every test file.
///
/// `SharedPreferencesAsync` throws on construction when no platform backend is
/// registered, so anything building the app would fail. Registering an
/// in-memory backend here also guarantees no test can read or write the real
/// device preferences.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  SharedPreferencesAsyncPlatform.instance ??=
      InMemorySharedPreferencesAsync.empty();

  await testMain();
}
