import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/budget_status.dart';

// Spent vs limit for one category. Level is shown by color AND an
// icon + label, so it never depends on color alone.
class BudgetProgressRow extends StatelessWidget {
  const BudgetProgressRow({super.key, required this.status, this.trailing});

  final BudgetStatus status;
  final Widget? trailing;

  static (Color, IconData, String) _style(BudgetStatus s) => switch (s.level) {
    BudgetLevel.safe => (
      AppColors.brand,
      FluentIcons.checkmark_circle_20_regular,
      'Aman',
    ),
    BudgetLevel.warning => (
      AppColors.warning,
      FluentIcons.warning_20_regular,
      'Hampir habis',
    ),
    BudgetLevel.over => (
      AppColors.expense,
      FluentIcons.error_circle_20_regular,
      'Melebihi',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon, String label) = _style(status);
    final double remaining = status.remaining;
    final Widget? end = trailing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                status.categoryName,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            ?end,
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: status.ratio.clamp(0.0, 1.0),
            minHeight: 10,
            color: color,
            backgroundColor: AppColors.muted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${CurrencyFormatter.format(status.spent)} dari '
          '${CurrencyFormatter.format(status.limit)} · '
          '${remaining >= 0 ? 'sisa ${CurrencyFormatter.format(remaining)}' : 'lebih ${CurrencyFormatter.format(-remaining)}'}',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
