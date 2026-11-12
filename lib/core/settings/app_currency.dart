import 'package:equatable/equatable.dart';

// Display currency. Changing it only swaps the symbol; amounts are not converted.
class AppCurrency extends Equatable {
  const AppCurrency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  static const AppCurrency idr = AppCurrency(
    code: 'IDR',
    name: 'Rupiah Indonesia',
    symbol: 'Rp',
  );

  static const List<AppCurrency> supported = [
    idr,
    AppCurrency(code: 'USD', name: 'Dolar Amerika', symbol: r'$'),
    AppCurrency(code: 'EUR', name: 'Euro', symbol: '€'),
    AppCurrency(code: 'SGD', name: 'Dolar Singapura', symbol: r'S$'),
    AppCurrency(code: 'MYR', name: 'Ringgit Malaysia', symbol: 'RM'),
    AppCurrency(code: 'SAR', name: 'Riyal Saudi', symbol: 'SAR'),
    AppCurrency(code: 'JPY', name: 'Yen Jepang', symbol: '¥'),
    AppCurrency(code: 'AUD', name: 'Dolar Australia', symbol: r'A$'),
    AppCurrency(code: 'GBP', name: 'Pound Inggris', symbol: '£'),
    AppCurrency(code: 'CNY', name: 'Yuan Tiongkok', symbol: 'CN¥'),
  ];

  // Unknown or missing codes fall back to Rupiah.
  static AppCurrency fromCode(String? code) =>
      supported.firstWhere((c) => c.code == code, orElse: () => idr);

  final String code;
  final String name;
  final String symbol;

  @override
  List<Object?> get props => [code];
}
