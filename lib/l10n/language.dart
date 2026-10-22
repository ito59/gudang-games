import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The languages the app speaks. Indonesian first: it is the default.
enum AppLanguage {
  id('Bahasa Indonesia'),
  en('English');

  const AppLanguage(this.label);

  /// Always written in the language itself, so somebody who cannot read the
  /// current one can still find theirs.
  final String label;

  Locale get locale => Locale(name);

  static AppLanguage fromCode(String? code) => values.firstWhere(
    (l) => l.name == code,
    orElse: () => LanguageController.defaultLanguage,
  );

  /// The language in use, for code that has no [BuildContext] — a
  /// repository's error message, a formatter. Widgets use [L10nContext.tr],
  /// which also rebuilds them when the language changes.
  static AppLanguage current = LanguageController.defaultLanguage;
}

/// Picks the text for the current language, outside the widget tree.
///
/// Inside a `build` method use `context.tr(...)` instead: this one does not
/// make the widget rebuild when somebody switches language.
String tr(String id, String en) =>
    AppLanguage.current == AppLanguage.id ? id : en;

extension L10nContext on BuildContext {
  /// The Indonesian or English text, by the app's current language.
  ///
  /// Reads the locale through [Localizations], so the calling widget is
  /// rebuilt when the language changes.
  String tr(String id, String en) =>
      Localizations.localeOf(this).languageCode == 'id' ? id : en;

  AppLanguage get language =>
      AppLanguage.fromCode(Localizations.localeOf(this).languageCode);
}

/// Remembers the chosen language on the device.
class LanguageController extends ChangeNotifier {
  LanguageController({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync() {
    AppLanguage.current = _language;
  }

  static const storageKey = 'language';

  /// Used until somebody picks one. Tests switch it to English, which is
  /// what their finders were written against.
  static AppLanguage defaultLanguage = AppLanguage.id;

  final SharedPreferencesAsync _preferences;

  AppLanguage _language = defaultLanguage;

  AppLanguage get language => _language;

  Future<void> load() async {
    try {
      final stored = await _preferences.getString(storageKey);
      if (stored != null) _apply(AppLanguage.fromCode(stored));
    } catch (_) {
      // Unreadable preferences fall back to the default language.
    }
  }

  Future<void> choose(AppLanguage language) async {
    _apply(language);
    try {
      await _preferences.setString(storageKey, language.name);
    } catch (_) {
      // Still switched for this session; it just will not be remembered.
    }
  }

  void _apply(AppLanguage language) {
    AppLanguage.current = language;
    if (language == _language) return;
    _language = language;
    notifyListeners();
  }
}

class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController super.notifier,
    required super.child,
  });

  static LanguageController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null, 'No LanguageScope above this context.');
    return scope!.notifier!;
  }
}
