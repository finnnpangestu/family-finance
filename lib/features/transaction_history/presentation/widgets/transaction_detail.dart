import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/transaction_entry.dart';
import '../controllers/history_controller.dart';

// Full detail of one entry; [onDeleted] lets the mobile sheet close itself.
class TransactionDetail extends ConsumerWidget {
  const TransactionDetail({super.key, required this.entry, this.onDeleted});

  final TransactionEntry entry;
  final VoidCallback? onDeleted;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Hapus transaksi?',
      message:
          '${entry.title} sebesar ${CurrencyFormatter.formatRupiah(entry.amount)} '
          'akan dihapus permanen.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(historyControllerProvider.notifier).delete(entry);
      if (!context.mounted) return;
      AppFeedback.showSuccess(context, 'Transaksi dihapus');
      onDeleted?.call();
    } catch (_) {
      if (context.mounted) {
        AppFeedback.showError(context, 'Gagal menghapus transaksi');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color color = entry.isIncome ? AppColors.income : AppColors.expense;
    final String? note = entry.note;
    final String? itemName = entry.itemName;
    final String mode = entry.isIncome
        ? 'Pemasukan'
        : entry.isLumpsum
        ? 'Pengeluaran · Catat Cepat'
        : 'Pengeluaran · Catat Rinci';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(mode, style: AppTypography.caption.copyWith(color: color)),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${entry.isIncome ? '+' : '-'}${CurrencyFormatter.formatRupiah(entry.amount)}',
            style: AppTypography.displayLarge.copyWith(color: color),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailRow(
          icon: FluentIcons.tag_24_regular,
          label: entry.isIncome ? 'Sumber' : 'Kategori',
          value: entry.categoryName,
        ),
        if (itemName != null)
          _DetailRow(
            icon: FluentIcons.receipt_24_regular,
            label: 'Item',
            value: itemName,
          ),
        _DetailRow(
          icon: FluentIcons.calendar_ltr_24_regular,
          label: 'Tanggal',
          value: DateFormatter.long(entry.date),
        ),
        if (note != null)
          _DetailRow(
            icon: FluentIcons.note_24_regular,
            label: 'Catatan',
            value: note,
          ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Hapus Transaksi',
          icon: FluentIcons.delete_24_regular,
          variant: AppButtonVariant.destructive,
          onPressed: () => _delete(context, ref),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyLarge)),
        ],
      ),
    );
  }
}
