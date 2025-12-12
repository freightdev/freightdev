// core/services/auth_service.dart
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../configs/env.dart';
import 'logger.dart';

class ZitadelAuthService {
  final FlutterAppAuth _appAuth = FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _idTokenKey = 'id_token';

  // Get from Env config
  String get _zitadelUrl => Env.zitadelUrl;
  String get _clientId => Env.zitadelClientId;
  String get _redirectUrl => Env.zitadelRedirectUrl;

  Future<AuthResult> login() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          discoveryUrl: '$_zitadelUrl/.well-known/openid-configuration',
          scopes: ['openid', 'profile', 'email', 'offline_access', 
                   'urn:zitadel:iam:org:project:id:${Env.zitadelProjectId}:aud'],
        ),
      );

      if (result != null) {
        await _storeTokens(result);
        _logger.info('Login successful');
        return AuthResult.success(result.accessToken!);
      }
      
      return AuthResult.failure('Login cancelled');
    } catch (e, stackTrace) {
      _logger.error('Login failed', e, stackTrace);
      return AuthResult.failure(e.toString());
    }
  }

  Future<void> _storeTokens(AuthorizationTokenResponse result) async {
    await _storage.write(key: _accessTokenKey, value: result.accessToken);
    await _storage.write(key: _refreshTokenKey, value: result.refreshToken);
    await _storage.write(key: _idTokenKey, value: result.idToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<Map<String, dynamic>?> getUserClaims() async {
    final idToken = await _storage.read(key: _idTokenKey);
    if (idToken == null) return null;
    
    // Decode JWT to get user info
    final parts = idToken.split('.');
    if (parts.length != 3) return null;
    
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return json.decode(decoded);
  }

  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return null;

      final result = await _appAuth.token(TokenRequest(
        _clientId,
        _redirectUrl,
        refreshToken: refreshToken,
        discoveryUrl: '$_zitadelUrl/.well-known/openid-configuration',
      ));

      if (result != null) {
        await _storeTokens(result);
        return result.accessToken;
      }
    } catch (e) {
      _logger.error('Token refresh failed', e);
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _logger.info('Logout successful');
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }
}

class AuthResult {
  final bool success;
  final String? token;
  final String? error;

  AuthResult.success(this.token) : success = true, error = null;
  AuthResult.failure(this.error) : success = false, token = null;
}