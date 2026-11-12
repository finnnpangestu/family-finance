import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/amount_field.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/category_picker.dart';
import '../../../../core/widgets/form_submit_area.dart';
import '../../../categories/data/category_repository.dart';
import '../../../dashboard/domain/models/expense.dart';
import '../../data/budget_repository.dart';
import '../../domain/budget_status.dart';

// Add a budget, or edit one when [existing] is given.
Future<void> openBudgetSheet(
  BuildContext context, {
  BudgetStatus? existing,
}) async {
  final bool? saved = await showAppBottomSheet<bool>(
    context: context,
    title: existing == null ? 'Tambah Anggaran' : 'Ubah Anggaran',
    child: _BudgetForm(existing: existing),
  );
  if ((saved ?? false) && context.mounted) {
    AppFeedback.showSuccess(context, 'Anggaran disimpan');
  }
}

class _BudgetForm extends ConsumerStatefulWidget {
  const _BudgetForm({this.existing});

  final BudgetStatus? existing;

  @override
  ConsumerState<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<_BudgetForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _category = TextEditingController(
    text: widget.existing?.categoryName,
  );
  late final TextEditingController _limit = TextEditingController(
    text: widget.existing == null
        ? null
        : CurrencyFormatter.formatGrouped(widget.existing!.limit),
  );
  final SubmitController _submit = SubmitController();

  @override
  void dispose() {
    _category.dispose();
    _limit.dispose();
    _submit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final double? limit = CurrencyFormatter.parse(_limit.text);
    if (limit == null) return;
    final String category = _category.text.trim();
    final String? previous = widget.existing?.categoryName;

    final bool saved = await _submit.run(() async {
      final BudgetRepository repo = ref.read(budgetRepositoryProvider);
      // Renaming the category moves the budget instead of duplicating it.
      if (previous != null && previous != category) await repo.remove(previous);
      await repo.upsert(category, limit);
      ref.read(financeRevisionProvider.notifier).bump();
    }, errorMessage: 'Gagal menyimpan anggaran. Silakan coba lagi.');
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> categories = [
      // Quick-mode spending lands here, so it can be budgeted too.
      Expense.lumpsumCategory,
      ...?ref.watch(expenseCategoriesProvider).valueOrNull,
    ];

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CategoryPicker(
              controller: _category,
              options: categories,
              label: 'Kategori pengeluaran',
              requiredMessage: 'Pilih atau tulis kategori',
            ),
            const SizedBox(height: AppSpacing.lg),
            AmountField(controller: _limit, label: 'Batas per bulan'),
            const SizedBox(height: AppSpacing.xl),
            FormSubmitArea(
              controller: _submit,
              label: 'Simpan Anggaran',
              icon: FluentIcons.checkmark_24_regular,
              color: AppColors.primary,
              onSubmit: _save,
            ),
          ],
        ),
      ),
    );
  }
}
