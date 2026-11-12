import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/subpage_scaffold.dart';
import '../../data/budget_repository.dart';
import '../../domain/budget_status.dart';
import '../widgets/budget_form.dart';
import '../widgets/budget_progress_row.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubpageScaffold(
      title: 'Anggaran',
      subtitle: 'Bulan ${DateFormatter.monthYear(DateTime.now())}',
      children: [
        AppButton(
          label: 'Tambah Anggaran',
          icon: FluentIcons.add_24_regular,
          onPressed: () => openBudgetSheet(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _BudgetList(),
      ],
    );
  }
}

class _BudgetList extends ConsumerWidget {
  const _BudgetList();

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    BudgetStatus status,
  ) async {
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Hapus anggaran ${status.categoryName}?',
      message: 'Pengeluaran di kategori ini tidak lagi dipantau.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(budgetRepositoryProvider).remove(status.categoryName);
      ref.read(financeRevisionProvider.notifier).bump();
    } catch (error) {
      debugPrint('Remove budget failed: $error');
      if (context.mounted) AppFeedback.showError(context, 'Gagal menghapus');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BudgetStatus>> value = ref.watch(
      budgetStatusProvider,
    );
    final List<BudgetStatus> statuses = value.valueOrNull ?? const [];
    if (value.isLoading && statuses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (statuses.isEmpty) {
      return Text(
        'Belum ada anggaran. Tentukan batas pengeluaran per kategori, '
        'misalnya Makan & Dapur Rp 2.000.000 per bulan.',
        style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
      );
    }
    return Column(
      children: [
        for (final BudgetStatus status in statuses)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Material(
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                side: const BorderSide(color: AppColors.border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                onTap: () => openBudgetSheet(context, existing: status),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.lg,
                  ),
                  child: BudgetProgressRow(
                    status: status,
                    trailing: IconButton(
                      tooltip: 'Hapus anggaran',
                      color: AppColors.expense,
                      onPressed: () => _remove(context, ref, status),
                      icon: const Icon(FluentIcons.delete_24_regular),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Text(
          'Ketuk anggaran untuk mengubah batasnya.',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
