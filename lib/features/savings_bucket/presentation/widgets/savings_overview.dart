import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../controllers/savings_controller.dart';

// Free balance vs. money parked in buckets.
class SavingsOverview extends StatelessWidget {
  const SavingsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _Figure(
            label: 'Saldo bebas',
            color: AppColors.income,
            selector: _selectFree,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _Figure(
            label: 'Total di pos',
            color: AppColors.savings,
            selector: _selectAllocated,
          ),
        ),
      ],
    );
  }
}

double _selectFree(SavingsState s) => s.freeBalance;
double _selectAllocated(SavingsState s) => s.totalAllocated;

class _Figure extends ConsumerWidget {
  const _Figure({
    required this.label,
    required this.color,
    required this.selector,
  });

  final String label;
  final Color color;
  final double Function(SavingsState state) selector;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double value = ref.watch(savingsControllerProvider.select(selector));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.formatRupiah(value),
                style: AppTypography.headingMedium.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
