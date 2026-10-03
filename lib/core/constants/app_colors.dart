import 'package:flutter/material.dart';

/// App color palette matching the Connect HR Android theme
class AppColors {
  AppColors._();

  // Primary Indigo & Secondary Teal Brand Colors
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF4338CA);
  static const Color indigo900 = Color(0xFF312E81);

  static const Color primary100 = Color(0xFFE0E7FF);
  static const Color primary600 = Color(0xFF4F46E5);
  static const Color primary700 = Color(0xFF4338CA);
  static const Color primary800 = Color(0xFF312E81);

  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal700 = Color(0xFF0F766E);

  // Backgrounds & Surfaces
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2D2D2D);
  static const Color darkOnSurfaceVariant = Color(0xFFE5E7EB);

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFE2E8F0);
  static const Color lightOnSurfaceVariant = Color(0xFF334155);

  // Error & Accent Colors
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFB91C1C);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);

  // Success & Warning
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccessContainer = Color(0xFF065F46);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF92400E);
}
