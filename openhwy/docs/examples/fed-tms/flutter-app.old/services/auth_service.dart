import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'local_storage_service.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  Future<User> login(String email, String password) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final accessToken = response.data['access_token'] as String;
    final refreshToken = response.data['refresh_token'] as String;
    final userData = response.data['user'] as Map<String, dynamic>;
    final user = User.fromJson(userData);

    // Save tokens and user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userKey, jsonEncode(userData));
    await LocalStorageService.saveCurrentUser(user);

    return user;
  }

  Future<User> register({
    required String email,
    required String password,
    String role = 'dispatcher', // Default to dispatcher role
  }) async {
    final response = await _apiClient.post(
      '/auth/signup',
      data: {
        'email': email,
        'password': password,
        'role': role,
      },
    );

    final accessToken = response.data['access_token'] as String;
    final refreshToken = response.data['refresh_token'] as String;
    final userData = response.data['user'] as Map<String, dynamic>;
    final user = User.fromJson(userData);

    // Save tokens and user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userKey, jsonEncode(userData));
    await LocalStorageService.saveCurrentUser(user);

    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
    await LocalStorageService.clearCurrentUser();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<User?> getCurrentUser() async {
    final cachedUser = LocalStorageService.getCurrentUser();
    if (cachedUser != null) {
      return cachedUser;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) {
      return null;
    }

    try {
      // Use /auth/validate endpoint to validate token and get user info
      final response = await _apiClient.get('/auth/validate');
      if (response.data['valid'] == true) {
        // Construct user from validation response
        final userData = {
          'id': response.data['user_id'],
          'email': prefs.getString('user_email') ?? '',
          'role': 'dispatcher',
          'tier': response.data['tier'],
        };
        final user = User.fromJson(userData);
        await LocalStorageService.saveCurrentUser(user);
        return user;
      }
      return null;
    } catch (e) {
      // Try to refresh token if validation fails
      return await _refreshAndRetry();
    }
  }

  Future<User?> _refreshAndRetry() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken == null) {
      return null;
    }

    try {
      final response = await _apiClient.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      final accessToken = response.data['access_token'] as String;
      final newRefreshToken = response.data['refresh_token'] as String;
      final userData = response.data['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      await prefs.setString(_tokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, newRefreshToken);
      await prefs.setString(_userKey, jsonEncode(userData));
      await LocalStorageService.saveCurrentUser(user);

      return user;
    } catch (e) {
      // Refresh failed, clear everything
      await logout();
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> resetPassword(String email) async {
    // Password reset not yet implemented in backend
    throw Exception('Password reset not yet implemented');
  }

  Future<Map<String, dynamic>> validateToken() async {
    final response = await _apiClient.get('/auth/validate');
    return response.data as Map<String, dynamic>;
  }
}
