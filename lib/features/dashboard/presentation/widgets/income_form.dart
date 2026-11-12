import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/amount_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/category_picker.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/form_submit_area.dart';
import '../../domain/models/income.dart';
import '../controllers/transaction_actions.dart';

// Stateful only to own its text controllers; pops `true` after saving.
class IncomeForm extends ConsumerStatefulWidget {
  const IncomeForm({super.key});

  @override
  ConsumerState<IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends ConsumerState<IncomeForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _category = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final ValueNotifier<DateTime> _date = ValueNotifier(DateTime.now());
  final SubmitController _submit = SubmitController();

  @override
  void dispose() {
    _category.dispose();
    _amount.dispose();
    _note.dispose();
    _date.dispose();
    _submit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final double? amount = CurrencyFormatter.parse(_amount.text);
    if (amount == null) return;
    final String note = _note.text.trim();

    final bool saved = await _submit.run(
      () => ref
          .read(transactionActionsProvider)
          .addIncome(
            Income(
              categoryName: _category.text.trim(),
              amount: amount,
              date: _date.value,
              note: note.isEmpty ? null : note,
            ),
          ),
      errorMessage: 'Gagal menyimpan pemasukan. Silakan coba lagi.',
    );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> categories =
        ref.watch(incomeCategoriesProvider).valueOrNull ?? const [];

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CategoryPicker(
              controller: _category,
              options: categories,
              label: 'Sumber pemasukan',
              requiredMessage: 'Pilih atau tulis sumber pemasukan',
            ),
            const SizedBox(height: AppSpacing.lg),
            AmountField(controller: _amount),
            const SizedBox(height: AppSpacing.lg),
            ValueListenableBuilder<DateTime>(
              valueListenable: _date,
              builder: (context, date, _) =>
                  DateField(value: date, onChanged: (d) => _date.value = d),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _note,
              label: 'Catatan (opsional)',
              textInputAction: TextInputAction.done,
              maxLength: 120,
            ),
            const SizedBox(height: AppSpacing.xl),
            FormSubmitArea(
              controller: _submit,
              label: 'Simpan Pemasukan',
              icon: FluentIcons.checkmark_24_regular,
              color: AppColors.income,
              onSubmit: _save,
            ),
          ],
        ),
      ),
    );
  }
}
