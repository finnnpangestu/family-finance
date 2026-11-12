import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/dashboard_state.dart';

// Hero: free balance up top, this month's in/out tiles underneath (PRD F-01).
class BalanceHeroCard extends StatelessWidget {
  const BalanceHeroCard({super.key});

  static const Color _onDarkMuted = AppColors.onHeroMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroStart, AppColors.heroEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                FluentIcons.wallet_24_regular,
                color: _onDarkMuted,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Sisa Saldo Bebas',
                  style: AppTypography.bodyMedium.copyWith(color: _onDarkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const _BalanceValue(),
          const _AllocatedNote(),
          const SizedBox(height: AppSpacing.xl),
          Text(
            DateFormatter.monthYear(DateTime.now()),
            style: AppTypography.caption.copyWith(color: _onDarkMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              Expanded(child: _FlowTile(isIncome: true)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: _FlowTile(isIncome: false)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceValue extends ConsumerWidget {
  const _BalanceValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double balance = ref.watch(
      dashboardControllerProvider.select((s) => s.freeBalance),
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        CurrencyFormatter.format(balance),
        style: AppTypography.displayLarge.copyWith(
          color: AppColors.onPrimary,
          fontSize: 36,
          height: 44 / 36,
        ),
      ),
    );
  }
}

class _AllocatedNote extends ConsumerWidget {
  const _AllocatedNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double allocated = ref.watch(
      dashboardControllerProvider.select((s) => s.totalAllocated),
    );
    if (allocated <= 0) return const SizedBox.shrink();
    return Text(
      'Sudah dikurangi pos tabungan '
      '${CurrencyFormatter.format(allocated)}',
      style: AppTypography.caption.copyWith(
        color: BalanceHeroCard._onDarkMuted,
      ),
    );
  }
}

// Translucent tile; icon chip keeps the green/red meaning, value stays white.
class _FlowTile extends ConsumerWidget {
  const _FlowTile({required this.isIncome});

  final bool isIncome;

  static double _income(DashboardState s) => s.totalIncome;
  static double _expense(DashboardState s) => s.totalExpense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double value = ref.watch(
      dashboardControllerProvider.select(isIncome ? _income : _expense),
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: AppSpacing.md,
            children: [
              Icon(
                isIncome
                    ? FluentIcons.arrow_down_left_24_regular
                    : FluentIcons.arrow_up_right_24_regular,
                size: 16,
                color: AppColors.onPrimary,
              ),

              Text(
                isIncome ? 'Masuk' : 'Keluar',
                style: AppTypography.caption.copyWith(
                  color: BalanceHeroCard._onDarkMuted,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(value),
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
