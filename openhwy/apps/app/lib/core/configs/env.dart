// core/configs/env.dart
abstract class Env {
  // Existing configs...
  static String get apiBaseUrl => _getEnv('API_BASE_URL');
  
  // Add Zitadel configs
  static String get zitadelUrl => _getEnv('ZITADEL_URL');
  static String get zitadelClientId => _getEnv('ZITADEL_CLIENT_ID');
  static String get zitadelProjectId => _getEnv('ZITADEL_PROJECT_ID');
  static String get zitadelRedirectUrl => _getEnv('ZITADEL_REDIRECT_URL');
  
  static String _getEnv(String key) {
    return const String.fromEnvironment(key);
  }
}