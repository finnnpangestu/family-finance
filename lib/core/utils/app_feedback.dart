import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

abstract final class AppFeedback {
  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, AppColors.income);

  static void showError(BuildContext context, String message) =>
      _show(context, message, AppColors.expense);

  // Pages use shadcn Scaffold (no Material ScaffoldMessenger), so feedback
  // goes through the ToastLayer that ShadcnApp provides.
  static void _show(BuildContext context, String message, Color color) {
    shadcn.showToast(
      context: context,
      location: shadcn.ToastLocation.bottomCenter,
      showDuration: const Duration(seconds: 3),
      builder: (context, overlay) => GestureDetector(
        onTap: overlay.close,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // Returns true only when the user explicitly confirms.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actionsPadding: const EdgeInsets.all(AppSpacing.lg),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(96, AppSpacing.minTouchTarget),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, AppSpacing.minTouchTarget),
              backgroundColor: destructive
                  ? AppColors.expense
                  : AppColors.primary,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
