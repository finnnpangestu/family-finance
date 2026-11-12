import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/page_header.dart';
import '../../domain/transaction_entry.dart';
import '../widgets/share_report_button.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(title: 'Riwayat', action: ShareReportButton()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: HistoryFilterBar(),
        ),
        const SizedBox(height: AppSpacing.md),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: MonthTotals(),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: HistoryList(
              onEntryTap: (entry) => _openDetail(context, entry),
            ),
          ),
        ),
      ],
    );
  }
}
