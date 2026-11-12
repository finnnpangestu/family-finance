import 'package:ff/core/utils/amount_input_formatter.dart';
import 'package:ff/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('CurrencyFormatter', () {
    test('formats rupiah with dot separators', () {
      expect(CurrencyFormatter.format(1500000), 'Rp 1.500.000');
      expect(CurrencyFormatter.format(0), 'Rp 0');
      expect(CurrencyFormatter.format(-25000), '-Rp 25.000');
    });

    test('parses grouped input back to a number', () {
      expect(CurrencyFormatter.parse('1.500.000'), 1500000);
      expect(CurrencyFormatter.parse('Rp 300.000'), 300000);
      expect(CurrencyFormatter.parse(''), isNull);
      expect(CurrencyFormatter.parse('abc'), isNull);
    });
  });

  test('compact formats axis labels', () {
    expect(CurrencyFormatter.compact(0), '0');
    expect(CurrencyFormatter.compact(750000), '750 rb');
    expect(CurrencyFormatter.compact(2500000), '2,5 jt');
    expect(CurrencyFormatter.compact(15000000), '15 jt');
    expect(CurrencyFormatter.compact(1200000000), '1,2 M');
    expect(CurrencyFormatter.compact(-3000000), '-3 jt');
  });

  group('AmountInputFormatter', () {
    const AmountInputFormatter formatter = AmountInputFormatter();

    TextEditingValue type(String text, [String old = '']) =>
        formatter.formatEditUpdate(
          TextEditingValue(text: old),
          TextEditingValue(text: text),
        );

    test('adds thousand separators and strips non-digits', () {
      expect(type('300000').text, '300.000');
      expect(type('12a34').text, '1.234');
    });

    test('drops leading zeros and clears empty input', () {
      expect(type('0050').text, '50');
      expect(type('').text, '');
    });

    test('rejects input beyond the digit limit', () {
      final String tooLong = '9' * (AmountInputFormatter.maxDigits + 1);
      expect(type(tooLong, '1').text, '1');
    });
  });
}
