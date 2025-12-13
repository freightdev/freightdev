import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Highway Journey Theme
  static const roadBlack = Color(0xFF0A0A0F);
  static const asphaltGray = Color(0xFF1A1A2E);
  static const concreteGray = Color(0xFF2A2A3E);
  static const yellowLine = Color(0xFFFBBF24);
  static const warningOrange = Color(0xFFF97316);
  static const truckRed = Color(0xFFEF4444);
  static const highwayBlue = Color(0xFF3B82F6);
  static const forestGreen = Color(0xFF10B981);
  static const skyBlue = Color(0xFF60A5FA);
  static const sunrisePurple = Color(0xFFA855F7);
  static const dawnPink = Color(0xFFEC4899);
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF9FAFB);
  static const textGray = Color(0xFF9CA3AF);

  // Gradients
  static const gradientSunrise = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [yellowLine, warningOrange, truckRed],
  );

  static const gradientHighway = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [highwayBlue, sunrisePurple],
  );

  static const gradientForest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forestGreen, Color(0xFF059669)],
  );

  static const gradientNight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [asphaltGray, roadBlack],
  );

  // Status Colors
  static const statusSuccess = forestGreen;
  static const statusWarning = warningOrange;
  static const statusError = truckRed;
  static const statusInfo = highwayBlue;

  // Border Colors
  static final borderGray = white.withOpacity(0.1);
  static final borderLight = white.withOpacity(0.05);
}
