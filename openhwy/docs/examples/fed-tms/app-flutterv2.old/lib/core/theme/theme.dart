import 'package:flutter/material.dart';

class AppTheme {
  // Purple shades
  static const purplePrimary = Color(0xFFD946EF);
  static const purpleLight = Color(0xFFF0ABFC);
  static const purpleDark = Color(0xFFA21CAF);

  // Orange shades
  static const orangePrimary = Color(0xFFFB923C);
  static const orangeLight = Color(0xFFFDBA74);
  static const orangeDark = Color(0xFFEA580C);

  // Blue shades
  static const bluePrimary = Color(0xFF3B82F6);
  static const blueLight = Color(0xFF60A5FA);
  static const blueDark = Color(0xFF1D4ED8);

  // Green shades
  static const greenPrimary = Color(0xFF10B981);
  static const greenLight = Color(0xFF34D399);
  static const greenDark = Color(0xFF059669);

  // Red/Error shades
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFF87171);
  static const errorDark = Color(0xFFDC2626);

  // Background gradients
  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A24),
      Color(0xFF0F0F16),
    ],
  );

  static const purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD946EF),
      Color(0xFFA855F7),
    ],
  );

  static const orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFB923C),
      Color(0xFFF59E0B),
    ],
  );

  static const blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6),
      Color(0xFF2563EB),
    ],
  );
}

extension GradientText on Text {
  Widget withGradient(Gradient gradient) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: this,
    );
  }
}
