import 'package:intl/intl.dart';

abstract final class CurrencyFormatter {
  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  static final NumberFormat _grouped = NumberFormat.decimalPattern('id_ID');

  // e.g. 1500000 -> "Rp 1.500.000"; negatives keep the sign in front.
  static String formatRupiah(double amount) {
    final String formatted = _rupiah.format(amount.abs());
    return amount < 0 ? '-$formatted' : formatted;
  }

  // Digits with dot separators, used inside amount inputs.
  static String formatGrouped(num amount) => _grouped.format(amount);

  // Parses "1.500.000" (or "Rp 1.500.000") back to 1500000.
  static double? parse(String input) {
    final String digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }
}
