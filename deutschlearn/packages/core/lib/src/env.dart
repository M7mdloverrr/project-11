import 'dart:convert';

/// Backend configuration, injected at build time with
/// `flutter run --dart-define-from-file=../../.env` (see SETUP.md).
///
/// Only the public URL and the anon/publishable key belong here. A
/// service-role / secret key is rejected so it can never ship in an app.
class AppEnv {
  const AppEnv({required this.supabaseUrl, required this.supabaseAnonKey});

  factory AppEnv.fromEnvironment() => const AppEnv(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  static const unconfigured = AppEnv(supabaseUrl: '', supabaseAnonKey: '');

  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Human-readable problems; empty when the backend can be used.
  List<String> get issues {
    final result = <String>[];
    final url = supabaseUrl.trim();
    final key = supabaseAnonKey.trim();
    if (url.isEmpty) {
      result.add('SUPABASE_URL is missing');
    } else {
      final uri = Uri.tryParse(url);
      final placeholder = url.contains('YOUR_PROJECT') || url.contains('<');
      if (uri == null || !uri.hasScheme || uri.host.isEmpty || placeholder) {
        result.add('SUPABASE_URL is not a valid URL');
      } else if (uri.scheme != 'https' && !_isLocalHost(uri.host)) {
        result.add('SUPABASE_URL must use https');
      }
    }
    if (key.isEmpty) {
      result.add('SUPABASE_ANON_KEY is missing');
    } else if (key.contains('YOUR_') || key.contains('<')) {
      result.add('SUPABASE_ANON_KEY is still the placeholder value');
    } else if (isSecretKey(key)) {
      result.add('SUPABASE_ANON_KEY is a service-role/secret key. Use the anon (publishable) key instead');
    }
    return result;
  }

  bool get isConfigured => issues.isEmpty;

  static bool _isLocalHost(String host) => host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';

  /// True for Supabase secret keys: new-style `sb_secret_...` or a legacy JWT
  /// whose payload has `"role": "service_role"`.
  static bool isSecretKey(String key) {
    if (key.startsWith('sb_secret_')) return true;
    final parts = key.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final json = jsonDecode(payload);
      return json is Map && json['role'] == 'service_role';
    } on FormatException {
      return false;
    }
  }
}
