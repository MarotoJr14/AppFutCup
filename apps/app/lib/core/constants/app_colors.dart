import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFDEBA3B);
  static const Color primaryDark = Color(0xFFB8962A);
  static const Color bronze = Color(0xFFCD7F32);

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceAlt = Color(0xFF2A2A2A);
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFEEEEEE);
  static const Color darkHint = Color(0xFF888888);
  static const Color darkDivider = Color(0xFF333333);

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightSurfaceAlt = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF121212);
  static const Color lightOnSurface = Color(0xFF121212);
  static const Color lightHint = Color(0xFF666666);
  static const Color lightDivider = Color(0xFFDDDDDD);

  static const Color onPrimary = Color(0xFF121212);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color goalColor = Color(0xFF4CAF50);
  static const Color yellowCard = Color(0xFFFFEB3B);
  static const Color redCard = Color(0xFFF44336);

  static bool _isDark = true;
  static void setIsDark(bool v) => _isDark = v;
  static bool get isDark => _isDark;

  static Color get background => _isDark ? darkBackground : lightBackground;
  static Color get surface => _isDark ? darkSurface : lightSurface;
  static Color get surfaceAlt => _isDark ? darkSurfaceAlt : lightSurfaceAlt;
  static Color get onBackground => _isDark ? darkOnBackground : lightOnBackground;
  static Color get onSurface => _isDark ? darkOnSurface : lightOnSurface;
  static Color get hint => _isDark ? darkHint : lightHint;
  static Color get divider => _isDark ? darkDivider : lightDivider;
}
