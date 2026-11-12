import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/dashboard_summary.dart';
import '../controllers/dashboard_controller.dart';

// Total income this month (Income A + B + ...) with each stream's share.
class IncomeStreamsCard extends StatelessWidget {
  const IncomeStreamsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderColor: AppColors.border,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.incomeSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  FluentIcons.money_24_regular,
                  color: AppColors.income,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Sumber Pemasukan',
                  style: AppTypography.headingMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Total bulan ini',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const _TotalIncome(),
          const SizedBox(height: AppSpacing.lg),
          const _StreamList(),
        ],
      ),
    );
  }
}

class _TotalIncome extends ConsumerWidget {
  const _TotalIncome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double total = ref.watch(
      dashboardControllerProvider.select((s) => s.totalIncome),
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        CurrencyFormatter.format(total),
        style: AppTypography.headingLarge.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StreamList extends ConsumerWidget {
  const _StreamList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<IncomeStreamTotal> streams = ref.watch(
      dashboardControllerProvider.select((s) => s.summary.incomeStreams),
    );
    if (streams.isEmpty) {
      return Text(
        'Belum ada pemasukan bulan ini.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }
    final double total = streams.fold(0, (sum, s) => sum + s.amount);

    return Column(
      children: [
        for (final IncomeStreamTotal stream in streams)
          _StreamRow(
            stream: stream,
            share: total == 0 ? 0 : stream.amount / total,
          ),
      ],
    );
  }
}

class _StreamRow extends StatelessWidget {
  const _StreamRow({required this.stream, required this.share});

  final IncomeStreamTotal stream;
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
                  stream.categoryName,
                  style: AppTypography.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CurrencyFormatter.format(stream.amount),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.muted),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: share.clamp(0.0, 1.0),
                    child: const ColoredBox(color: AppColors.chartIncome),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${(share * 100).round()}% dari total',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
