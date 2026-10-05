import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the fonts bundled in pubspec.yaml so goldens render with the real
/// type scale instead of the test fallback face.
Future<void> loadAppFonts() async {
  const families = <String, List<String>>{
    'Sora': [
      'assets/fonts/Sora-500.ttf',
      'assets/fonts/Sora-600.ttf',
      'assets/fonts/Sora-700.ttf',
    ],
    'Hanken Grotesk': [
      'assets/fonts/HankenGrotesk-400.ttf',
      'assets/fonts/HankenGrotesk-500.ttf',
    ],
    'JetBrains Mono': ['assets/fonts/JetBrainsMono-500.ttf'],
    'MaterialSymbolsOutlined': ['assets/fonts/MaterialSymbolsOutlined.ttf'],
  };

  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
}
