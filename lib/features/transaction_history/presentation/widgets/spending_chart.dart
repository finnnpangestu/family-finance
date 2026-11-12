import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/transaction_entry.dart';
import '../controllers/history_controller.dart';

// Lightweight horizontal bar chart of the month's spending per category.
class SpendingChart extends ConsumerWidget {
  const SpendingChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CategorySpending> spending = ref.watch(
      historyControllerProvider.select((s) => s.spending),
    );
    final double total = spending.fold(0, (sum, s) => sum + s.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(FluentIcons.data_bar_horizontal_24_regular),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Pengeluaran per Kategori',
                  style: AppTypography.headingMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (spending.isEmpty)
              Text(
                'Belum ada pengeluaran di bulan ini.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (final CategorySpending item in spending)
                _Bar(item: item, share: total == 0 ? 0 : item.amount / total),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.item, required this.share});

  final CategorySpending item;
  final double share;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.categoryName,
                  style: AppTypography.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${CurrencyFormatter.formatRupiah(item.amount)} · ${(share * 100).round()}%',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 12,
              color: AppColors.expense,
              backgroundColor: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
