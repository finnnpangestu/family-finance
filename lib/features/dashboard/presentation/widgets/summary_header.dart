import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/models/dashboard_summary.dart';
import '../controllers/dashboard_controller.dart';

// Total income of the month (Income A + Income B + ...) with its breakdown.
class SummaryHeader extends StatelessWidget {
  const SummaryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                FluentIcons.wallet_24_regular,
                color: AppColors.onPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Total Pemasukan · ${DateFormatter.monthYear(DateTime.now())}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.border,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const _TotalIncomeText(),
          const SizedBox(height: AppSpacing.lg),
          const _IncomeStreamList(),
        ],
      ),
    );
  }
}

class _TotalIncomeText extends ConsumerWidget {
  const _TotalIncomeText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double totalIncome = ref.watch(
      dashboardControllerProvider.select((s) => s.totalIncome),
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        CurrencyFormatter.formatRupiah(totalIncome),
        style: AppTypography.displayLarge.copyWith(color: AppColors.onPrimary),
      ),
    );
  }
}

class _IncomeStreamList extends ConsumerWidget {
  const _IncomeStreamList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<IncomeStreamTotal> streams = ref.watch(
      dashboardControllerProvider.select((s) => s.summary.incomeStreams),
    );
    final TextStyle style = AppTypography.bodyMedium.copyWith(
      color: AppColors.onPrimary,
    );

    if (streams.isEmpty) {
      return Text(
        'Belum ada pemasukan bulan ini.',
        style: style.copyWith(color: AppColors.border),
      );
    }
    return Column(
      children: [
        for (final IncomeStreamTotal stream in streams)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    stream.categoryName,
                    style: style,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatRupiah(stream.amount),
                  style: style.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
