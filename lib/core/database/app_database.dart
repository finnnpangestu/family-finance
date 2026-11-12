import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'tables/expenses_table.dart';
import 'tables/incomes_table.dart';
import 'tables/savings_buckets_table.dart';

// Lazily opens a single SQLite connection shared by every repository.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path})
    : _factory = factory ?? databaseFactory,
      _path = path;

  static const String fileName = 'ff_family_finance.db';
  static const int schemaVersion = 1;

  // Tables included in backups, in insert order.
  static const List<String> tableNames = [
    IncomesTable.name,
    ExpensesTable.name,
    SavingsBucketsTable.name,
  ];

  final DatabaseFactory _factory;
  final String? _path;
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final String path =
        _path ?? p.join(await _factory.getDatabasesPath(), fileName);
    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: schemaVersion, onCreate: _onCreate),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final Batch batch = db.batch()
      ..execute(IncomesTable.createSql)
      ..execute(IncomesTable.createDateIndexSql)
      ..execute(ExpensesTable.createSql)
      ..execute(ExpensesTable.createDateIndexSql)
      ..execute(SavingsBucketsTable.createSql);
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final Future<Database>? opening = _opening;
    _opening = null;
    if (opening != null) await (await opening).close();
  }
}
