import 'package:flutter/services.dart';

import 'currency_formatter.dart';

// Keeps only digits and renders thousand separators while typing.
class AmountInputFormatter extends TextInputFormatter {
  const AmountInputFormatter();

  // 15 digits stays well within double integer precision.
  static const int maxDigits = 15;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > maxDigits) return oldValue;

    final String formatted = CurrencyFormatter.formatGrouped(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
