import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../controllers/history_controller.dart';

// In/out totals for the entries currently listed.
class MonthTotals extends ConsumerWidget {
  const MonthTotals({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double income = ref.watch(
      historyControllerProvider.select((s) => s.totalIncome),
    );
    final double expense = ref.watch(
      historyControllerProvider.select((s) => s.totalExpense),
    );

    return Row(
      children: [
        Expanded(
          child: _Total(
            label: 'Masuk',
            amount: income,
            color: AppColors.income,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _Total(
            label: 'Keluar',
            amount: expense,
            color: AppColors.expense,
          ),
        ),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.formatRupiah(amount),
                style: AppTypography.bodyLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
