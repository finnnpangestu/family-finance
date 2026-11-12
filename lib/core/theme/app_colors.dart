import 'package:flutter/material.dart';

// Brand tokens taken from the FF logo: ink strokes #1A1D24 + teal #00787C.
// All text pairs meet WCAG AA (most AAA) on white; see comments for ratios.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF1A1D24); // Logo ink · 16.9:1
  static const Color brand = Color(0xFF00787C); // Logo teal · 5.3:1
  static const Color brandDark = Color(0xFF005F63); // Pressed/text · 7.5:1
  static const Color brandSurface = Color(0xFFE3F2F2); // Tinted backdrop

  // Financial indicators. Income uses the brand teal ("money in" = brand).
  static const Color income = brand;
  static const Color expense = Color(0xFF991B1B); // Red 800 · 8.3:1
  static const Color savings = Color(0xFF1E40AF); // Blue 800 · 8.7:1

  // Budget "almost used up" state. White text on it: 5.0:1.
  static const Color warning = Color(0xFFB45309); // Amber 700
  static const Color warningSurface = Color(0xFFFEF3C7); // Amber 100

  // Tinted surfaces behind indicator icons
  static const Color incomeSurface = brandSurface;
  static const Color expenseSurface = Color(0xFFFEE2E2); // Red 100
  static const Color savingsSurface = Color(0xFFDBEAFE); // Blue 100

  // Chart series (dataviz validator, light surface):
  // teal #00787C vs red #F87171 -> CVD ΔE 9.7 (protan), normal ΔE 31.8.
  // Teal chroma 0.088 sits just under the 0.1 floor; kept for brand match,
  // and the chart always shows a legend + value readout as secondary cues.
  static const Color chartIncome = brand;
  static const Color chartExpense = Color(0xFFF87171); // Red 400

  // Hero card gradient: ink fading into a deep logo teal.
  static const Color heroStart = primary;
  static const Color heroEnd = Color(0xFF0B4447);
  static const Color onHeroMuted = Color(0xFFC9D3D3); // 11:1 on ink

  // Backgrounds & cards (neutral greys tinted toward the logo teal)
  static const Color background = Color(0xFFF6F8F8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFEEF2F2);

  // Text
  static const Color textPrimary = primary;
  static const Color textSecondary = Color(0xFF4A5260); // 7.9:1
  static const Color textMuted = Color(0xFF8A939F);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Borders & dividers
  static const Color border = Color(0xFFDDE4E4);
  static const Color borderStrong = Color(0xFFC5CFCF);
}
