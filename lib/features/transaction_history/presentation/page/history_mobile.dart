import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/transaction_entry.dart';
import '../widgets/history_filter_bar.dart';
import '../widgets/history_list.dart';
import '../widgets/month_totals.dart';
import '../widgets/transaction_detail.dart';

class HistoryMobile extends StatelessWidget {
  const HistoryMobile({super.key});

  void _openDetail(BuildContext context, TransactionEntry entry) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Detail Transaksi',
      child: SingleChildScrollView(
        child: Builder(
          builder: (sheetContext) => TransactionDetail(
            entry: entry,
            onDeleted: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HistoryFilterBar(),
          const SizedBox(height: AppSpacing.md),
          const MonthTotals(),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: HistoryList(
              onEntryTap: (entry) => _openDetail(context, entry),
            ),
          ),
        ],
      ),
    );
  }
}
