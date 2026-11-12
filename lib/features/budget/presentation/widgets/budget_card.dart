import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/budget_status.dart';
import '../../data/budget_repository.dart';
import '../page/budget_page.dart';
import 'budget_progress_row.dart';

// Dashboard summary: the categories closest to their limit.
class BudgetCard extends ConsumerWidget {
  const BudgetCard({super.key});

  static const int _maxRows = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<BudgetStatus> statuses =
        ref.watch(budgetStatusProvider).valueOrNull ?? const [];

    void openPage() => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const BudgetPage()));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  FluentIcons.target_arrow_24_regular,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Anggaran Bulan Ini',
                  style: AppTypography.headingMedium,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandDark,
                  minimumSize: const Size(64, AppSpacing.minTouchTarget),
                ),
                onPressed: openPage,
                child: Text(statuses.isEmpty ? 'Atur' : 'Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (statuses.isEmpty)
            Text(
              'Tentukan batas pengeluaran per kategori agar diingatkan '
              'sebelum kebablasan.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            for (final BudgetStatus status in statuses.take(_maxRows))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: BudgetProgressRow(status: status),
              ),
        ],
      ),
    );
  }
}
