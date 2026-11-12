import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/models/dashboard_summary.dart';
import '../controllers/dashboard_controller.dart';

// Total income of the month (Income A + B + ...) with its breakdown.
class SummaryHeader extends StatelessWidget {
  const SummaryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                FluentIcons.wallet_24_regular,
                color: Color(0xFFCBD5E1),
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Total Pemasukan · ${DateFormatter.monthYear(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w500,
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
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFFFFF),
          height: 1.2,
        ),
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

    if (streams.isEmpty) {
      return const Text(
        'Belum ada pemasukan bulan ini.',
        style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
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
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFE2E8F0),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatRupiah(stream.amount),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFFFFFFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
