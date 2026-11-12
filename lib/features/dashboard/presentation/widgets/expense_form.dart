import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/amount_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/category_picker.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/form_submit_area.dart';
import '../../../../core/widgets/repeat_monthly_switch.dart';
import '../../domain/models/expense.dart';
import '../../../budget/domain/budget_status.dart';
import '../../../categories/data/category_repository.dart';
import '../../../family_members/widgets/member_picker.dart';
import '../controllers/transaction_actions.dart';

enum ExpenseMode { lumpsum, itemized }

// Dual-mode expense recorder (PRD F-03); pops `true` after saving.
class ExpenseForm extends ConsumerStatefulWidget {
  const ExpenseForm({super.key});

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ValueNotifier<ExpenseMode> _mode = ValueNotifier(ExpenseMode.lumpsum);
  final ValueNotifier<DateTime> _date = ValueNotifier(DateTime.now());
  final ValueNotifier<int?> _member = ValueNotifier(null);
  final ValueNotifier<bool> _repeat = ValueNotifier(false);
  final TextEditingController _lumpsumAmount = TextEditingController();
  final TextEditingController _category = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final ValueNotifier<List<_ItemControllers>> _items = ValueNotifier([
    _ItemControllers(),
  ]);
  final SubmitController _submit = SubmitController();

  @override
  void dispose() {
    _mode.dispose();
    _date.dispose();
    _member.dispose();
    _repeat.dispose();
    _lumpsumAmount.dispose();
    _category.dispose();
    _note.dispose();
    for (final _ItemControllers item in _items.value) {
      item.dispose();
    }
    _items.dispose();
    _submit.dispose();
    super.dispose();
  }

  void _addItem() => _items.value = [..._items.value, _ItemControllers()];

  void _removeItem(_ItemControllers item) {
    if (_items.value.length <= 1) return;
    _items.value = [..._items.value]..remove(item);
    // Dispose after the row has left the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => item.dispose());
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String note = _note.text.trim();
    final String? cleanNote = note.isEmpty ? null : note;
    final TransactionActions actions = ref.read(transactionActionsProvider);
    final DateTime date = _date.value;
    final int? memberId = _member.value;
    final bool repeat = _repeat.value;

    final Future<List<BudgetAlert>> Function() write;
    if (_mode.value == ExpenseMode.lumpsum) {
      final double? amount = CurrencyFormatter.parse(_lumpsumAmount.text);
      if (amount == null) return;
      write = () => actions.addLumpsumExpense(
        amount: amount,
        date: date,
        note: cleanNote,
        memberId: memberId,
        repeatMonthly: repeat,
      );
    } else {
      final List<ExpenseItemDraft> drafts = [
        for (final _ItemControllers item in _items.value)
          ExpenseItemDraft(
            itemName: item.name.text.trim(),
            amount: CurrencyFormatter.parse(item.amount.text) ?? 0,
          ),
      ];
      write = () => actions.addItemizedExpenses(
        categoryName: _category.text.trim(),
        items: drafts,
        date: date,
        note: cleanNote,
        memberId: memberId,
        repeatMonthly: repeat,
      );
    }

    List<BudgetAlert> alerts = const [];
    final bool saved = await _submit.run(
      () async => alerts = await write(),
      errorMessage: 'Gagal menyimpan pengeluaran. Silakan coba lagi.',
    );
    // The sheet result carries any budget alerts for the caller to show.
    if (saved && mounted) Navigator.of(context).pop(alerts);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<ExpenseMode>(
              valueListenable: _mode,
              builder: (context, mode, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<ExpenseMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ExpenseMode.lumpsum,
                        label: Text('Catat Cepat'),
                        icon: Icon(FluentIcons.flash_24_regular),
                      ),
                      ButtonSegment(
                        value: ExpenseMode.itemized,
                        label: Text('Catat Rinci'),
                        icon: Icon(FluentIcons.text_bullet_list_ltr_24_regular),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => _mode.value = s.first,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    mode == ExpenseMode.lumpsum
                        ? 'Masukkan total pengeluaran hari itu.'
                        : 'Catat per item, misalnya Listrik dan Air.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (mode == ExpenseMode.lumpsum)
                    AmountField(
                      controller: _lumpsumAmount,
                      label: 'Total pengeluaran',
                    )
                  else
                    _ItemizedSection(
                      category: _category,
                      items: _items,
                      onAdd: _addItem,
                      onRemove: _removeItem,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ValueListenableBuilder<DateTime>(
              valueListenable: _date,
              builder: (context, date, _) =>
                  DateField(value: date, onChanged: (d) => _date.value = d),
            ),
            const SizedBox(height: AppSpacing.lg),
            MemberPicker(selected: _member),
            RepeatMonthlySwitch(enabled: _repeat, date: _date),
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
              label: 'Simpan Pengeluaran',
              icon: FluentIcons.checkmark_24_regular,
              color: AppColors.expense,
              onSubmit: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemizedSection extends ConsumerWidget {
  const _ItemizedSection({
    required this.category,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  final TextEditingController category;
  final ValueNotifier<List<_ItemControllers>> items;
  final VoidCallback onAdd;
  final ValueChanged<_ItemControllers> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> categories =
        ref.watch(expenseCategoriesProvider).valueOrNull ?? const [];

    return ValueListenableBuilder<List<_ItemControllers>>(
      valueListenable: items,
      builder: (context, rows, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CategoryPicker(
            controller: category,
            options: categories,
            label: 'Kategori',
            requiredMessage: 'Pilih atau tulis kategori',
          ),
          const SizedBox(height: AppSpacing.lg),
          for (int i = 0; i < rows.length; i++)
            _ItemRow(
              key: ObjectKey(rows[i]),
              index: i + 1,
              controllers: rows[i],
              onRemove: rows.length > 1 ? () => onRemove(rows[i]) : null,
            ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
              side: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            onPressed: onAdd,
            icon: const Icon(FluentIcons.add_24_regular),
            label: const Text('Tambah Item'),
          ),
          const SizedBox(height: AppSpacing.md),
          _ItemsTotal(rows: rows),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.index,
    required this.controllers,
    required this.onRemove,
  });

  final int index;
  final _ItemControllers controllers;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? remove = onRemove;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Item $index', style: AppTypography.caption),
                ),
                if (remove != null)
                  IconButton(
                    tooltip: 'Hapus item',
                    onPressed: remove,
                    color: AppColors.expense,
                    icon: const Icon(FluentIcons.delete_24_regular),
                  ),
              ],
            ),
            AppTextField(
              controller: controllers.name,
              label: 'Nama item',
              hint: 'Contoh: Listrik',
              requiredMessage: 'Isi nama item',
            ),
            const SizedBox(height: AppSpacing.sm),
            AmountField(
              controller: controllers.amount,
              textInputAction: TextInputAction.next,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsTotal extends StatelessWidget {
  const _ItemsTotal({required this.rows});

  final List<_ItemControllers> rows;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([for (final r in rows) r.amount]),
      builder: (context, _) {
        final double total = rows.fold(
          0,
          (sum, r) => sum + (CurrencyFormatter.parse(r.amount.text) ?? 0),
        );
        return Row(
          children: [
            Expanded(child: Text('Total', style: AppTypography.bodyLarge)),
            Text(
              CurrencyFormatter.format(total),
              style: AppTypography.headingMedium.copyWith(
                color: AppColors.expense,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ItemControllers {
  final TextEditingController name = TextEditingController();
  final TextEditingController amount = TextEditingController();

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}
