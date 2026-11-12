import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/dashboard_controller.dart';

// Shows load errors without replacing the last known figures.
class DashboardStatusBanner extends ConsumerWidget {
  const DashboardStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? error = ref.watch(
      dashboardControllerProvider.select((s) => s.errorMessage),
    );
    if (error == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Material(
        color: AppColors.expenseSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(
                FluentIcons.warning_24_regular,
                color: AppColors.expense,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  error,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.expense,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, AppSpacing.minTouchTarget),
                  foregroundColor: AppColors.expense,
                ),
                onPressed: () =>
                    ref.read(dashboardControllerProvider.notifier).refresh(),
                child: const Text('Ulangi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
