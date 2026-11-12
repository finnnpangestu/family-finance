import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

abstract final class AppFeedback {
  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, AppColors.income);

  static void showError(BuildContext context, String message) =>
      _show(context, message, AppColors.expense);

  static void _show(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
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
