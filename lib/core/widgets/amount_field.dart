import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../utils/amount_input_formatter.dart';
import '../utils/currency_formatter.dart';

// Rupiah input that always opens the native numeric keypad.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label = 'Nominal',
    this.maxAmount,
    this.maxAmountMessage,
    this.textInputAction = TextInputAction.done,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final double? maxAmount;
  final String? maxAmountMessage;
  final TextInputAction textInputAction;
  final bool autofocus;

  String? _validate(String? value) {
    final double? amount = CurrencyFormatter.parse(value ?? '');
    if (amount == null || amount <= 0) return 'Masukkan nominal lebih dari 0';
    final double? max = maxAmount;
    if (max != null && amount > max) {
      return maxAmountMessage ??
          'Maksimal ${CurrencyFormatter.formatRupiah(max)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      inputFormatters: const [AmountInputFormatter()],
      style: AppTypography.headingMedium,
      decoration: InputDecoration(labelText: label, prefixText: 'Rp '),
      validator: _validate,
    );
  }
}
