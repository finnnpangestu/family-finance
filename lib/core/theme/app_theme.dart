import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  // shadcn widgets (buttons, cards, inputs) in the logo palette.
  static const shadcn.ColorScheme shadcnColors = shadcn.ColorScheme(
    brightness: Brightness.light,
    background: AppColors.background,
    foreground: AppColors.textPrimary,
    card: AppColors.card,
    cardForeground: AppColors.textPrimary,
    popover: AppColors.card,
    popoverForeground: AppColors.textPrimary,
    primary: AppColors.primary,
    primaryForeground: AppColors.onPrimary,
    secondary: AppColors.brandSurface,
    secondaryForeground: AppColors.brandDark,
    muted: AppColors.muted,
    mutedForeground: AppColors.textSecondary,
    accent: AppColors.brandSurface,
    accentForeground: AppColors.brandDark,
    destructive: AppColors.expense,
    destructiveForeground: AppColors.onPrimary,
    border: AppColors.border,
    input: AppColors.border,
    ring: AppColors.brand,
    chart1: AppColors.chartIncome,
    chart2: AppColors.chartExpense,
    chart3: AppColors.savings,
    chart4: AppColors.brandDark,
    chart5: AppColors.textMuted,
  );

  static ThemeData get light {
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.brand,
        onSecondary: AppColors.onPrimary,
        tertiary: AppColors.savings,
        error: AppColors.expense,
        surface: AppColors.card,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: AppTypography.headingLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.expense),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.expense, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: AppTypography.bodyMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.fromHeight(AppSpacing.minTouchTarget),
          ),
          textStyle: WidgetStatePropertyAll(
            AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.onPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        titleTextStyle: AppTypography.headingMedium,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
