import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'tables/app_settings_table.dart';
import 'tables/budgets_table.dart';
import 'tables/categories_table.dart';
import 'tables/expenses_table.dart';
import 'tables/family_members_table.dart';
import 'tables/incomes_table.dart';
import 'tables/recurring_transactions_table.dart';
import 'tables/savings_buckets_table.dart';

// Lazily opens a single SQLite connection shared by every repository.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path, String? fileName})
    : _factory = factory ?? databaseFactory,
      _path = path,
      _fileName = fileName ?? deviceFileName;

  // Device profile (no Google account) + device-wide settings.
  static const String deviceFileName = 'ff_family_finance.db';

  // v2: app_settings. v3: categories, members, budgets, recurring rules,
  // member_id on transactions.
  static const int schemaVersion = 3;

  // Tables that belong to a profile (backup, move-to-account), in insert
  // order: members first because transactions reference them.
  static const List<String> tableNames = [
    FamilyMembersTable.name,
    CategoriesTable.name,
    IncomesTable.name,
    ExpensesTable.name,
    SavingsBucketsTable.name,
    BudgetsTable.name,
    RecurringTransactionsTable.name,
  ];

  // Single source of truth for what a backup / profile move carries.
  static const Map<String, List<String>> profileColumns = {
    FamilyMembersTable.name: [
      FamilyMembersTable.id,
      FamilyMembersTable.memberName,
    ],
    CategoriesTable.name: [
      CategoriesTable.id,
      CategoriesTable.type,
      CategoriesTable.categoryName,
    ],
    IncomesTable.name: [
      IncomesTable.id,
      IncomesTable.categoryName,
      IncomesTable.amount,
      IncomesTable.date,
      IncomesTable.note,
      IncomesTable.memberId,
    ],
    ExpensesTable.name: [
      ExpensesTable.id,
      ExpensesTable.isLumpsum,
      ExpensesTable.categoryName,
      ExpensesTable.itemName,
      ExpensesTable.amount,
      ExpensesTable.date,
      ExpensesTable.note,
      ExpensesTable.memberId,
    ],
    SavingsBucketsTable.name: [
      SavingsBucketsTable.id,
      SavingsBucketsTable.bucketName,
      SavingsBucketsTable.allocatedAmount,
      SavingsBucketsTable.targetAmount,
    ],
    BudgetsTable.name: [
      BudgetsTable.id,
      BudgetsTable.categoryName,
      BudgetsTable.monthlyLimit,
    ],
    RecurringTransactionsTable.name: [
      RecurringTransactionsTable.id,
      RecurringTransactionsTable.type,
      RecurringTransactionsTable.categoryName,
      RecurringTransactionsTable.itemName,
      RecurringTransactionsTable.amount,
      RecurringTransactionsTable.dayOfMonth,
      RecurringTransactionsTable.nextDue,
      RecurringTransactionsTable.note,
      RecurringTransactionsTable.memberId,
      RecurringTransactionsTable.active,
    ],
  };

  final DatabaseFactory _factory;
  final String? _path;
  final String _fileName;
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

  Future<String> _resolvePath() async =>
      _path ?? p.join(await _factory.getDatabasesPath(), _fileName);

  // True once the file was created; lets profiles tell "new" from "empty".
  Future<bool> exists() async =>
      _opening != null || await _factory.databaseExists(await _resolvePath());

  Future<Database> _open() async {
    final String path = await _resolvePath();
    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  // Fresh installs build the v1 schema and run every migration, so new and
  // upgraded databases always end up identical.
  Future<void> _onCreate(Database db, int version) async {
    final Batch batch = db.batch()
      ..execute(IncomesTable.createSql)
      ..execute(IncomesTable.createDateIndexSql)
      ..execute(ExpensesTable.createSql)
      ..execute(ExpensesTable.createDateIndexSql)
      ..execute(SavingsBucketsTable.createSql);
    await batch.commit(noResult: true);
    await _onUpgrade(db, 1, version);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await db.execute(AppSettingsTable.createSql);
    if (oldVersion < 3) await _migrateToV3(db);
  }

  Future<void> _migrateToV3(Database db) async {
    final Batch batch = db.batch()
      ..execute(FamilyMembersTable.createSql)
      ..execute(CategoriesTable.createSql)
      ..execute(BudgetsTable.createSql)
      ..execute(RecurringTransactionsTable.createSql)
      ..execute(
        'ALTER TABLE ${IncomesTable.name} ADD COLUMN ${IncomesTable.memberId} INTEGER',
      )
      ..execute(
        'ALTER TABLE ${ExpensesTable.name} ADD COLUMN ${ExpensesTable.memberId} INTEGER',
      );
    await batch.commit(noResult: true);
    await seedDefaultCategories(db);
    // Categories typed before v3 become editable list entries too.
    await syncCategoriesFromTransactions(db);
  }

  // Adds every category already used by a transaction (idempotent). Also
  // run after restoring backups made before the categories table existed.
  static Future<void> syncCategoriesFromTransactions(
    DatabaseExecutor db,
  ) async {
    await db.execute(
      'INSERT OR IGNORE INTO ${CategoriesTable.name} '
      '(${CategoriesTable.type}, ${CategoriesTable.categoryName}) '
      "SELECT DISTINCT '${CategoriesTable.typeIncome}', ${IncomesTable.categoryName} "
      'FROM ${IncomesTable.name}',
    );
    await db.execute(
      'INSERT OR IGNORE INTO ${CategoriesTable.name} '
      '(${CategoriesTable.type}, ${CategoriesTable.categoryName}) '
      "SELECT DISTINCT '${CategoriesTable.typeExpense}', ${ExpensesTable.categoryName} "
      'FROM ${ExpensesTable.name} WHERE ${ExpensesTable.isLumpsum} = 0',
    );
  }

  static Future<void> seedDefaultCategories(DatabaseExecutor db) async {
    final Batch batch = db.batch();
    for (final (String type, List<String> names) in [
      (CategoriesTable.typeIncome, CategoriesTable.defaultIncome),
      (CategoriesTable.typeExpense, CategoriesTable.defaultExpense),
    ]) {
      for (final String name in names) {
        batch.insert(CategoriesTable.name, {
          CategoriesTable.type: type,
          CategoriesTable.categoryName: name,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final Future<Database>? opening = _opening;
    _opening = null;
    if (opening != null) await (await opening).close();
  }
}
