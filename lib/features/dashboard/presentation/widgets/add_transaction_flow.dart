import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../budget/domain/budget_status.dart';
import 'expense_form.dart';
import 'income_form.dart';

enum _TransactionType { income, expense }

// Type chooser sheet, then the matching form sheet.
Future<void> openAddTransactionFlow(BuildContext context) async {
  final _TransactionType? type = await showAppBottomSheet<_TransactionType>(
    context: context,
    title: 'Tambah',
    child: const _TypeChooser(),
  );
  if (type == null || !context.mounted) return;

  // Income pops `true`; expense pops the budget alerts it triggered.
  final Object? result = await showAppBottomSheet<Object>(
    context: context,
    title: type == _TransactionType.income
        ? 'Tambah Pemasukan'
        : 'Tambah Pengeluaran',
    child: type == _TransactionType.income
        ? const IncomeForm()
        : const ExpenseForm(),
  );
  if (result == null || !context.mounted) return;
  if (result is List<BudgetAlert> && result.isNotEmpty) {
    AppFeedback.showWarning(
      context,
      'Tersimpan. ${result.map((a) => a.message).join(' ')}',
    );
    return;
  }
  AppFeedback.showSuccess(
    context,
    type == _TransactionType.income
        ? 'Pemasukan berhasil disimpan'
        : 'Pengeluaran berhasil disimpan',
  );
}

class _TypeChooser extends StatelessWidget {
  const _TypeChooser();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TypeTile(
          type: _TransactionType.income,
          icon: FluentIcons.arrow_circle_down_32_regular,
          label: 'Pemasukan',
          description: 'Gaji, hasil usaha, atau uang masuk lainnya',
          color: AppColors.income,
          surface: AppColors.incomeSurface,
        ),
        SizedBox(height: AppSpacing.md),
        _TypeTile(
          type: _TransactionType.expense,
          icon: FluentIcons.arrow_circle_up_32_regular,
          label: 'Pengeluaran',
          description: 'Belanja harian, tagihan, dan lainnya',
          color: AppColors.expense,
          surface: AppColors.expenseSurface,
        ),
        SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.surface,
  });

  final _TransactionType type;
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => Navigator.of(context).pop(type),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.headingMedium.copyWith(color: color),
                    ),
                    Text(
                      description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
