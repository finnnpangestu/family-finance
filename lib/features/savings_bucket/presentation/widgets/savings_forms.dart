import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/amount_input_formatter.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/amount_field.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/form_submit_area.dart';
import '../../domain/savings_bucket.dart';
import '../controllers/savings_controller.dart';

String? _describeSavingsError(Object error) =>
    error is SavingsRuleException ? error.message : null;

Future<void> openCreateBucketSheet(BuildContext context) async {
  final bool? saved = await showAppBottomSheet<bool>(
    context: context,
    title: 'Buat Pos Tabungan',
    child: const _CreateBucketForm(),
  );
  if ((saved ?? false) && context.mounted) {
    AppFeedback.showSuccess(context, 'Pos tabungan berhasil dibuat');
  }
}

Future<void> openFundSheet(
  BuildContext context, {
  required SavingsBucket bucket,
  required bool isWithdraw,
}) async {
  final bool? saved = await showAppBottomSheet<bool>(
    context: context,
    title: isWithdraw
        ? 'Ambil dari ${bucket.bucketName}'
        : 'Isi ${bucket.bucketName}',
    child: _FundForm(bucket: bucket, isWithdraw: isWithdraw),
  );
  if ((saved ?? false) && context.mounted) {
    AppFeedback.showSuccess(
      context,
      isWithdraw
          ? 'Dana dikembalikan ke saldo bebas'
          : 'Dana berhasil dialokasikan',
    );
  }
}

class _CreateBucketForm extends ConsumerStatefulWidget {
  const _CreateBucketForm();

  @override
  ConsumerState<_CreateBucketForm> createState() => _CreateBucketFormState();
}

class _CreateBucketFormState extends ConsumerState<_CreateBucketForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _target = TextEditingController();
  final SubmitController _submit = SubmitController();

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _submit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bool saved = await _submit.run(
      () => ref
          .read(savingsControllerProvider.notifier)
          .create(
            name: _name.text.trim(),
            targetAmount: CurrencyFormatter.parse(_target.text) ?? 0,
          ),
      errorMessage: 'Gagal membuat pos tabungan. Silakan coba lagi.',
    );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _name,
              label: 'Nama pos',
              hint: 'Contoh: Dana Darurat',
              requiredMessage: 'Isi nama pos tabungan',
            ),
            const SizedBox(height: AppSpacing.lg),
            // Optional, so it skips AmountField's "> 0" validation.
            TextFormField(
              controller: _target,
              keyboardType: TextInputType.number,
              inputFormatters: const [AmountInputFormatter()],
              style: AppTypography.headingMedium,
              decoration: const InputDecoration(
                labelText: 'Target (opsional)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FormSubmitArea(
              controller: _submit,
              label: 'Buat Pos',
              icon: FluentIcons.checkmark_24_regular,
              color: AppColors.savings,
              onSubmit: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _FundForm extends ConsumerStatefulWidget {
  const _FundForm({required this.bucket, required this.isWithdraw});

  final SavingsBucket bucket;
  final bool isWithdraw;

  @override
  ConsumerState<_FundForm> createState() => _FundFormState();
}

class _FundFormState extends ConsumerState<_FundForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final SubmitController _submit = SubmitController();

  @override
  void dispose() {
    _amount.dispose();
    _submit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final int? id = widget.bucket.id;
    if (id == null || !(_formKey.currentState?.validate() ?? false)) return;
    final double? amount = CurrencyFormatter.parse(_amount.text);
    if (amount == null) return;

    final SavingsController controller = ref.read(
      savingsControllerProvider.notifier,
    );
    final bool saved = await _submit.run(
      () => widget.isWithdraw
          ? controller.withdraw(id, amount)
          : controller.allocate(id, amount),
      errorMessage: 'Gagal memproses dana. Silakan coba lagi.',
      describeError: _describeSavingsError,
    );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final double freeBalance = ref.watch(
      savingsControllerProvider.select((s) => s.freeBalance),
    );
    final double limit = widget.isWithdraw
        ? widget.bucket.allocatedAmount
        : freeBalance;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isWithdraw
                  ? 'Isi pos saat ini: ${CurrencyFormatter.formatRupiah(limit)}'
                  : 'Saldo bebas tersedia: ${CurrencyFormatter.formatRupiah(limit)}',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AmountField(
              controller: _amount,
              autofocus: true,
              maxAmount: limit,
              maxAmountMessage: widget.isWithdraw
                  ? 'Melebihi isi pos'
                  : 'Melebihi saldo bebas',
            ),
            const SizedBox(height: AppSpacing.xl),
            FormSubmitArea(
              controller: _submit,
              label: widget.isWithdraw ? 'Ambil Dana' : 'Isi Dana',
              icon: widget.isWithdraw
                  ? FluentIcons.arrow_undo_24_regular
                  : FluentIcons.savings_24_regular,
              color: AppColors.savings,
              onSubmit: _save,
            ),
          ],
        ),
      ),
    );
  }
}
