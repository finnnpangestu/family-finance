import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/models/monthly_cashflow.dart';
import '../controllers/dashboard_controller.dart';
import 'cashflow_chart.dart';

// Chosen month in the chart; null follows the latest month.
final cashflowSelectionProvider =
    NotifierProvider.autoDispose<CashflowSelection, int?>(
      CashflowSelection.new,
    );

class CashflowSelection extends AutoDisposeNotifier<int?> {
  @override
  int? build() => null;

  void select(int index) => state = index;
}

class CashflowCard extends StatelessWidget {
  const CashflowCard({super.key, this.chartHeight = 200});

  // Tablet passes a taller plot to balance the two columns.
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderColor: AppColors.border,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle(),
          const SizedBox(height: AppSpacing.lg),
          _CashflowBody(chartHeight: chartHeight),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Icon(
            FluentIcons.data_bar_vertical_24_regular,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Arus Kas', style: AppTypography.headingMedium),
              Text(
                '6 bulan terakhir',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CashflowBody extends ConsumerWidget {
  const _CashflowBody({required this.chartHeight});

  final double chartHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<MonthlyCashflow> data = ref.watch(
      dashboardControllerProvider.select((s) => s.cashflow),
    );
    if (data.isEmpty || data.every((m) => m.isEmpty)) {
      return const _EmptyChart();
    }

    final int selected =
        (ref.watch(cashflowSelectionProvider) ?? data.length - 1).clamp(
          0,
          data.length - 1,
        );
    final MonthlyCashflow month = data[selected];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Readout(month: month),
        const SizedBox(height: AppSpacing.lg),
        CashflowChart(
          data: data,
          height: chartHeight,
          selectedIndex: selected,
          onSelect: ref.read(cashflowSelectionProvider.notifier).select,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ketuk atau geser grafik untuk melihat bulan lain.',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// Legend + values of the selected month; doubles as the series key.
class _Readout extends StatelessWidget {
  const _Readout({required this.month});

  final MonthlyCashflow month;

  @override
  Widget build(BuildContext context) {
    final double net = month.net;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          DateFormatter.monthYear(month.month),
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _LegendValue(
                color: AppColors.chartIncome,
                label: 'Pemasukan',
                value: month.income,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _LegendValue(
                color: AppColors.chartExpense,
                label: 'Pengeluaran',
                value: month.expense,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text.rich(
          TextSpan(
            text: 'Selisih  ',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text:
                    '${net >= 0 ? '+' : '−'}'
                    '${CurrencyFormatter.format(net.abs())}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: net >= 0 ? '  (surplus)' : '  (defisit)'),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendValue extends StatelessWidget {
  const _LegendValue({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
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
                  CurrencyFormatter.format(value),
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        'Grafik muncul setelah Anda mencatat pemasukan atau pengeluaran.',
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
