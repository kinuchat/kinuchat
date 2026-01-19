import 'package:flutter/material.dart';

/// MeshLink Typography System
/// Based on Section 7.1 of the specification
///
/// Font Family: "DM Sans" (body), "DM Mono" (code/IDs)
/// Fallback: system-ui, -apple-system, sans-serif
class AppTypography {
  AppTypography._();

  // Font families
  static const String bodyFont = 'DM Sans';
  static const String monoFont = 'DM Mono';

  // ============================================================================
  // Text Styles
  // ============================================================================

  /// Display: 32px / 40px line / -0.5 tracking / Bold
  static const TextStyle display = TextStyle(
    fontFamily: bodyFont,
    fontSize: 32,
    height: 40 / 32,
    letterSpacing: -0.5,
    fontWeight: FontWeight.bold,
  );

  /// Headline: 24px / 32px line / 0 tracking / SemiBold
  static const TextStyle headline = TextStyle(
    fontFamily: bodyFont,
    fontSize: 24,
    height: 32 / 24,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
  );

  /// Title: 20px / 28px line / 0 tracking / Medium
  static const TextStyle title = TextStyle(
    fontFamily: bodyFont,
    fontSize: 20,
    height: 28 / 20,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );

  /// Body: 16px / 24px line / 0 tracking / Regular
  static const TextStyle body = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );

  /// Body Small: 14px / 20px line / 0 tracking / Regular
  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );

  /// Caption: 12px / 16px line / 0.2 tracking / Regular
  static const TextStyle caption = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w400,
  );

  /// Mono: 14px / 20px line / 0 tracking / DM Mono
  static const TextStyle mono = TextStyle(
    fontFamily: monoFont,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );

  // ============================================================================
  // TextTheme
  // ============================================================================

  static TextTheme getTextTheme(Color textColor, Color textSecondaryColor) {
    return TextTheme(
      displayLarge: display.copyWith(color: textColor),
      headlineMedium: headline.copyWith(color: textColor),
      titleLarge: title.copyWith(color: textColor),
      bodyLarge: body.copyWith(color: textColor),
      bodyMedium: bodySmall.copyWith(color: textColor),
      bodySmall: caption.copyWith(color: textSecondaryColor),
      labelSmall: mono.copyWith(color: textSecondaryColor),
    );
  }
}
