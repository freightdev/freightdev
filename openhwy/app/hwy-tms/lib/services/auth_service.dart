import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'local_storage_service.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  Future<User> login(String email, String password) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final token = response.data['token'] as String;
    final userData = response.data['user'] as Map<String, dynamic>;
    final user = User.fromJson(userData);

    // Save token and user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userData));
    await LocalStorageService.saveCurrentUser(user);

    return user;
  }

  Future<User> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _apiClient.post(
      '/auth/register',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
      },
    );

    final token = response.data['token'] as String;
    final userData = response.data['user'] as Map<String, dynamic>;
    final user = User.fromJson(userData);

    // Save token and user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userData));
    await LocalStorageService.saveCurrentUser(user);

    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
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
      final response = await _apiClient.get('/auth/me');
      final user = User.fromJson(response.data as Map<String, dynamic>);
      await LocalStorageService.saveCurrentUser(user);
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> resetPassword(String email) async {
    await _apiClient.post(
      '/auth/reset-password',
      data: {'email': email},
    );
  }
}
