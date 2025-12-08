import 'package:flutter/material.dart';

class AppTheme {
  // OpenHWY Color Palette
  static const primaryBlue = Color(0xFF0EA5E9);
  static const accentCyan = Color(0xFF22D3EE);
  static const darkBg = Color(0xFF0F172A);
  static const cardBg = Color(0xFF1E293B);
  static const borderColor = Color(0xFF334155);
  
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xEF4444);
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentCyan,
        surface: cardBg,
        background: darkBg,
        error: error,
      ),
      
      // Card theme
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor.withOpacity(0.3)),
        ),
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        centerTitle: false,
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue.withOpacity(0.2),
          foregroundColor: accentCyan,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: primaryBlue.withOpacity(0.5)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      
      // Text theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: accentCyan,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Colors.white60,
        ),
      ),
    );
  }
}
