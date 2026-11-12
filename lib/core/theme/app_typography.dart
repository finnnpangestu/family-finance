import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

// Elderly-friendly type scale; nothing below 14pt (DESIGN_SYSTEM.md §1).
abstract final class AppTypography {
  static TextStyle _base(double size, double lineHeight, FontWeight weight) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      color: AppColors.textPrimary,
    );
  }

  static final TextStyle displayLarge = _base(32, 40, FontWeight.w700);
  static final TextStyle headingLarge = _base(24, 32, FontWeight.w600);
  static final TextStyle headingMedium = _base(20, 28, FontWeight.w600);
  static final TextStyle bodyLarge = _base(18, 26, FontWeight.w400);
  static final TextStyle bodyMedium = _base(16, 24, FontWeight.w400);
  static final TextStyle caption = _base(14, 20, FontWeight.w500);

  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    headlineLarge: headingLarge,
    headlineMedium: headingMedium,
    titleLarge: headingMedium,
    titleMedium: bodyLarge.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: caption,
    labelLarge: bodyLarge.copyWith(fontWeight: FontWeight.w600),
    labelMedium: caption,
    labelSmall: caption,
  );
}
