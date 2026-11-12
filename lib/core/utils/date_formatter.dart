import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static const String locale = 'id_ID';

  static final DateFormat _storage = DateFormat('yyyy-MM-dd');
  static final DateFormat _long = DateFormat('EEEE, d MMMM yyyy', locale);
  static final DateFormat _medium = DateFormat('d MMM yyyy', locale);
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', locale);

  // Sortable string persisted in SQLite.
  static String toStorage(DateTime date) => _storage.format(date);

  static DateTime fromStorage(String value) => _storage.parse(value);

  static String long(DateTime date) => _long.format(date);

  static String medium(DateTime date) => _medium.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);
}
