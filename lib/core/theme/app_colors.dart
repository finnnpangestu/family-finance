import 'package:flutter/material.dart';

// High-contrast Shadcn Slate/Emerald tokens (DESIGN_SYSTEM.md §3).
abstract final class AppColors {
  // Brand & financial indicators
  static const Color primary = Color(0xFF0F172A); // Slate 900
  static const Color income = Color(0xFF166534); // Emerald 800
  static const Color expense = Color(0xFF991B1B); // Red 800
  static const Color savings = Color(0xFF1E40AF); // Blue 800

  // Tinted surfaces behind indicator icons
  static const Color incomeSurface = Color(0xFFDCFCE7); // Emerald 100
  static const Color expenseSurface = Color(0xFFFEE2E2); // Red 100
  static const Color savingsSurface = Color(0xFFDBEAFE); // Blue 100

  // Backgrounds & cards
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color card = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFF1F5F9); // Slate 100

  // Text
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Borders & dividers
  static const Color border = Color(0xFFE2E8F0); // Slate 200
}
