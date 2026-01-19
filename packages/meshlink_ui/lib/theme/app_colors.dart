import 'package:flutter/material.dart';

/// MeshLink Color System
/// Based on Section 7.1 of the specification
class AppColors {
  AppColors._();

  // ============================================================================
  // Light Mode Colors
  // ============================================================================

  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF1B7F6E);
  static const Color lightPrimaryVariant = Color(0xFF145F52);
  static const Color lightSecondary = Color(0xFF6B5B95);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightDivider = Color(0xFFE5E5E5);

  // ============================================================================
  // Dark Mode Colors
  // ============================================================================

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkPrimary = Color(0xFF4ECDC4);
  static const Color darkPrimaryVariant = Color(0xFF3AA89E);
  static const Color darkSecondary = Color(0xFF9B8AC4);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkDivider = Color(0xFF333333);

  // ============================================================================
  // Semantic Colors (Mode-independent)
  // ============================================================================

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color meshActive = Color(0xFF00BCD4);
  static const Color bridgeActive = Color(0xFFFFB300);
  static const Color rallyMode = Color(0xFF7C4DFF);

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Get colors for the given brightness
  static ColorScheme getColorScheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    return ColorScheme(
      brightness: brightness,
      primary: isLight ? lightPrimary : darkPrimary,
      onPrimary: isLight ? Colors.white : Colors.black,
      secondary: isLight ? lightSecondary : darkSecondary,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: isLight ? lightSurface : darkSurface,
      onSurface: isLight ? lightTextPrimary : darkTextPrimary,
    );
  }
}
