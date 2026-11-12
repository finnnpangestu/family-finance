import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/transaction_entry.dart';
import '../controllers/history_controller.dart';
import '../widgets/share_report_button.dart';
import '../widgets/history_filter_bar.dart';
import '../widgets/history_list.dart';
import '../widgets/month_totals.dart';
import '../widgets/spending_chart.dart';
import '../widgets/transaction_detail.dart';

// Split view: list on the left, detail and spending chart on the right.
class HistoryTablet extends StatelessWidget {
  const HistoryTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'Riwayat Transaksi',
            action: ShareReportButton(),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HistoryFilterBar(),
                      const SizedBox(height: AppSpacing.md),
                      const MonthTotals(),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, _) => HistoryList(
                            highlightSelection: true,
                            onEntryTap: ref
                                .read(historyControllerProvider.notifier)
                                .select,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xxl),
                const Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: AppSpacing.xxxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SelectedDetailCard(),
                        SizedBox(height: AppSpacing.lg),
                        SpendingChart(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedDetailCard extends ConsumerWidget {
  const _SelectedDetailCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TransactionEntry? entry = ref.watch(
      historyControllerProvider.select((s) => s.selected),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: entry == null
            ? const EmptyView(
                icon: FluentIcons.receipt_48_regular,
                message: 'Pilih transaksi untuk melihat detail.',
              )
            : TransactionDetail(key: ValueKey(entry.key), entry: entry),
      ),
    );
  }
}
