import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../backup_setting/presentation/page/backup_page.dart';
import '../../../savings_bucket/presentation/page/savings_page.dart';
import '../../../transaction_history/presentation/page/history_page.dart';
import 'add_transaction_flow.dart';
import 'quick_action_button.dart';

// Single-hub navigation; replaces any bottom navigation bar.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuickActionButton(
          icon: FluentIcons.add_circle_32_regular,
          label: 'Tambah Transaksi',
          description: 'Catat pemasukan atau pengeluaran',
          highlighted: true,
          onTap: () => openAddTransactionFlow(context),
        ),
        const SizedBox(height: AppSpacing.md),
        QuickActionButton(
          icon: FluentIcons.history_32_regular,
          label: 'Riwayat Transaksi',
          description: 'Lihat dan cari catatan sebelumnya',
          onTap: () => _push(context, const HistoryPage()),
        ),
        const SizedBox(height: AppSpacing.md),
        QuickActionButton(
          icon: FluentIcons.savings_32_regular,
          label: 'Pos Tabungan',
          description: 'Sisihkan dana darurat & tabungan',
          onTap: () => _push(context, const SavingsPage()),
        ),
        const SizedBox(height: AppSpacing.md),
        QuickActionButton(
          icon: FluentIcons.cloud_arrow_up_32_regular,
          label: 'Backup Google Drive',
          description: 'Amankan data ke akun Google',
          onTap: () => _push(context, const BackupPage()),
        ),
      ],
    );
  }
}
