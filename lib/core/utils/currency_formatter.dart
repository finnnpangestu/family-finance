import 'package:intl/intl.dart';

import '../settings/app_currency.dart';

abstract final class CurrencyFormatter {
  static AppCurrency _currency = AppCurrency.idr;
  static NumberFormat _money = _build(AppCurrency.idr);
  static final NumberFormat _grouped = NumberFormat.decimalPattern('id_ID');

  // Amounts are whole numbers app-wide, so every currency shows 0 decimals.
  static NumberFormat _build(AppCurrency currency) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: '${currency.symbol} ',
    decimalDigits: 0,
  );

  static AppCurrency get currency => _currency;

  // Prefix for amount inputs, e.g. "Rp ".
  static String get prefix => '${_currency.symbol} ';

  // Called once at startup and whenever the user picks another currency.
  static void use(AppCurrency currency) {
    _currency = currency;
    _money = _build(currency);
  }

  // e.g. 1500000 -> "Rp 1.500.000"; negatives keep the sign in front.
  static String format(double amount) {
    final String formatted = _money.format(amount.abs());
    return amount < 0 ? '-$formatted' : formatted;
  }

  // Short axis labels: 2500000 -> "2,5 jt", 750000 -> "750 rb".
  static String compact(double amount) {
    final double v = amount.abs();
    final (double div, String unit) = switch (v) {
      >= 1e12 => (1e12, ' T'),
      >= 1e9 => (1e9, ' M'),
      >= 1e6 => (1e6, ' jt'),
      >= 1e3 => (1e3, ' rb'),
      _ => (1.0, ''),
    };
    final double scaled = v / div;
    // One decimal only below 10 so labels stay short.
    final String number = scaled < 10 && div > 1
        ? NumberFormat('#,##0.#', 'id_ID').format(scaled)
        : NumberFormat('#,##0', 'id_ID').format(scaled);
    return '${amount < 0 ? '-' : ''}$number$unit';
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
