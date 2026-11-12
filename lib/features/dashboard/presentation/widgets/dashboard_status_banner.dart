import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.expenseSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              FluentIcons.warning_24_regular,
              color: AppColors.expense,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(fontSize: 14, color: AppColors.expense),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GhostButton(
              onPressed: () =>
                  ref.read(dashboardControllerProvider.notifier).refresh(),
              child: const Text('Ulangi'),
            ),
          ],
        ),
      ),
    );
  }
}
