/// Where the backend lives.
///
/// The default is the deployed backend, so a build with no flags is a build
/// that works. Point it somewhere else per build without touching code:
///
/// ```sh
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
/// ```
///
/// For a local backend, give the machine's LAN address rather than
/// `localhost` — on a phone that means the phone itself, not the machine
/// running the API. Android permits cleartext only for those development
/// hosts (see `android/.../network_security_config.xml`); anything else has
/// to be HTTPS.
class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bebandargames.lds.co.id',
  );

  static Uri endpoint(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl/api/v1/$path').replace(queryParameters: query);

  /// Where a private broadcast channel is authorised. Under `/api` so the
  /// Sanctum token is the credential, not a session cookie.
  static Uri get broadcastAuth => Uri.parse('$baseUrl/api/broadcasting/auth');

  /// A public web page on the backend — the privacy policy, the terms — in
  /// [language] when the site has it, English otherwise, and dark to match
  /// the app: a WebView tells the page "light" whatever surrounds it.
  static Uri page(String path, {String language = 'en', String? section}) {
    final uri = Uri.parse('$baseUrl/$path').replace(
      queryParameters: {
        'lang': language == 'id' ? 'id' : 'en',
        'theme': 'dark',
      },
    );

    return section == null ? uri : uri.replace(fragment: section);
  }

  static const timeout = Duration(seconds: 8);
}
