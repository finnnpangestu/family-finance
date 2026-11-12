import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/dashboard_state.dart';

export 'indicator_card.dart' show IndicatorKind;

enum IndicatorKind { income, expense, balance }

// Financial indicator card using shadcn_flutter Card.
class IndicatorCard extends StatelessWidget {
  const IndicatorCard({super.key, required this.kind});

  final IndicatorKind kind;

  @override
  Widget build(BuildContext context) {
    final _IndicatorStyle style = _IndicatorStyle.of(kind);
    final theme = Theme.of(context);

    return Card(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: theme.colorScheme.border,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: style.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(style.icon, color: style.color, size: 26),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                _IndicatorValue(
                  selector: style.selector,
                  color: style.color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorValue extends ConsumerWidget {
  const _IndicatorValue({required this.selector, required this.color});

  final double Function(DashboardState state) selector;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double value = ref.watch(
      dashboardControllerProvider.select(selector),
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        CurrencyFormatter.formatRupiah(value),
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.3,
        ),
      ),
    );
  }
}

class _IndicatorStyle {
  const _IndicatorStyle({
    required this.label,
    required this.icon,
    required this.color,
    required this.surface,
    required this.selector,
  });

  factory _IndicatorStyle.of(IndicatorKind kind) => switch (kind) {
    IndicatorKind.income => const _IndicatorStyle(
      label: 'Masuk bulan ini',
      icon: FluentIcons.arrow_circle_down_24_regular,
      color: AppColors.income,
      surface: AppColors.incomeSurface,
      selector: _selectIncome,
    ),
    IndicatorKind.expense => const _IndicatorStyle(
      label: 'Keluar bulan ini',
      icon: FluentIcons.arrow_circle_up_24_regular,
      color: AppColors.expense,
      surface: AppColors.expenseSurface,
      selector: _selectExpense,
    ),
    IndicatorKind.balance => const _IndicatorStyle(
      label: 'Sisa saldo bebas',
      icon: FluentIcons.wallet_24_regular,
      color: AppColors.savings,
      surface: AppColors.savingsSurface,
      selector: _selectBalance,
    ),
  };

  final String label;
  final IconData icon;
  final Color color;
  final Color surface;
  final double Function(DashboardState state) selector;
}

double _selectIncome(DashboardState s) => s.totalIncome;
double _selectExpense(DashboardState s) => s.totalExpense;
double _selectBalance(DashboardState s) => s.freeBalance;
