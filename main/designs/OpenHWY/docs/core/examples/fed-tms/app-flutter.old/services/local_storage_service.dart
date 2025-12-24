import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/company.dart';
import '../models/user.dart';

class LocalStorageService {
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _companyBoxName = 'company';
  static const String _currentCompanyKey = 'current_company';
  static const String _userBox = 'cache';
  static const String _currentUserKey = 'current_user';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CompanyAdapter());
    }

    // Open boxes
    await Hive.openBox<Company>(_companyBoxName);
    await Hive.openBox('settings');
    await Hive.openBox('cache');
  }

  // Onboarding
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  static Future<void> setOnboardingComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, value);
  }

  // Company
  static Future<void> saveCompany(Company company) async {
    final box = Hive.box<Company>(_companyBoxName);
    await box.put(_currentCompanyKey, company);
  }

  static Company? getCurrentCompany() {
    final box = Hive.box<Company>(_companyBoxName);
    return box.get(_currentCompanyKey);
  }

  static Future<void> updateCompany(Company company) async {
    await saveCompany(company);
  }

  static Future<void> deleteCompany() async {
    final box = Hive.box<Company>(_companyBoxName);
    await box.delete(_currentCompanyKey);
  }

  static Future<void> saveCurrentUser(User user) async {
    final box = Hive.box(_userBox);
    await box.put(_currentUserKey, user.toJson());
  }

  static User? getCurrentUser() {
    final box = Hive.box(_userBox);
    final userData = box.get(_currentUserKey);
    if (userData == null) return null;
    return User.fromJson(Map<String, dynamic>.from(userData as Map));
  }

  static Future<void> clearCurrentUser() async {
    final box = Hive.box(_userBox);
    await box.delete(_currentUserKey);
  }

  // Settings
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box('settings');
    await box.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box('settings');
    return box.get(key, defaultValue: defaultValue);
  }

  // Cache
  static Future<void> cacheData(String key, dynamic value) async {
    final box = Hive.box('cache');
    await box.put(key, value);
  }

  static dynamic getCachedData(String key) {
    final box = Hive.box('cache');
    return box.get(key);
  }

  static Future<void> clearCache() async {
    final box = Hive.box('cache');
    await box.clear();
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await Hive.box<Company>(_companyBoxName).clear();
    await Hive.box('settings').clear();
    await Hive.box('cache').clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
