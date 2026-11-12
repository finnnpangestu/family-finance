import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/tables/expenses_table.dart';
import '../../../core/database/tables/incomes_table.dart';
import '../../../core/database/tables/savings_buckets_table.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../dashboard/domain/models/dashboard_summary.dart';
import '../domain/savings_bucket.dart';

typedef _Row = Map<String, Object?>;

final savingsRepositoryProvider = Provider<SavingsRepository>(
  (ref) => SavingsRepository(ref.watch(appDatabaseProvider)),
);

class SavingsRepository {
  const SavingsRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<List<SavingsBucket>> getAll() async {
    final Database db = await _db;
    final List<_Row> rows = await db.query(
      SavingsBucketsTable.name,
      orderBy: '${SavingsBucketsTable.id} ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<double> freeBalance() async => _freeBalance(await _db);

  Future<int> create({
    required String name,
    required double targetAmount,
  }) async {
    final Database db = await _db;
    return db.insert(SavingsBucketsTable.name, {
      SavingsBucketsTable.bucketName: name,
      SavingsBucketsTable.allocatedAmount: 0.0,
      SavingsBucketsTable.targetAmount: targetAmount,
    });
  }

  // Balance check and update share one transaction to avoid races.
  Future<void> allocate(int bucketId, double amount) async {
    _ensurePositive(amount);
    final Database db = await _db;
    await db.transaction((txn) async {
      final double free = await _freeBalance(txn);
      if (amount > free) {
        throw SavingsRuleException(
          'Saldo bebas tidak cukup. Tersedia ${CurrencyFormatter.formatRupiah(free)}.',
        );
      }
      await _changeAllocated(txn, bucketId, amount);
    });
  }

  Future<void> withdraw(int bucketId, double amount) async {
    _ensurePositive(amount);
    final Database db = await _db;
    await db.transaction((txn) async {
      final SavingsBucket bucket = await _find(txn, bucketId);
      if (amount > bucket.allocatedAmount) {
        throw SavingsRuleException(
          'Isi pos hanya ${CurrencyFormatter.formatRupiah(bucket.allocatedAmount)}.',
        );
      }
      await _changeAllocated(txn, bucketId, -amount);
    });
  }

  // Remaining funds flow back to the free balance automatically.
  Future<void> delete(int bucketId) async {
    final Database db = await _db;
    await db.delete(
      SavingsBucketsTable.name,
      where: '${SavingsBucketsTable.id} = ?',
      whereArgs: [bucketId],
    );
  }

  static void _ensurePositive(double amount) {
    if (amount <= 0) {
      throw const SavingsRuleException('Nominal harus lebih dari 0.');
    }
  }

  static Future<SavingsBucket> _find(DatabaseExecutor db, int id) async {
    final List<_Row> rows = await db.query(
      SavingsBucketsTable.name,
      where: '${SavingsBucketsTable.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const SavingsRuleException('Pos tabungan tidak ditemukan.');
    }
    return _fromRow(rows.first);
  }

  static Future<void> _changeAllocated(
    DatabaseExecutor db,
    int id,
    double delta,
  ) async {
    final int changed = await db.rawUpdate(
      'UPDATE ${SavingsBucketsTable.name} '
      'SET ${SavingsBucketsTable.allocatedAmount} = ${SavingsBucketsTable.allocatedAmount} + ? '
      'WHERE ${SavingsBucketsTable.id} = ?',
      [delta, id],
    );
    if (changed == 0) {
      throw const SavingsRuleException('Pos tabungan tidak ditemukan.');
    }
  }

  static Future<double> _freeBalance(DatabaseExecutor db) async {
    final List<_Row> rows = await db.rawQuery(
      'SELECT '
      '(SELECT IFNULL(SUM(${IncomesTable.amount}), 0) FROM ${IncomesTable.name}) AS income, '
      '(SELECT IFNULL(SUM(${ExpensesTable.amount}), 0) FROM ${ExpensesTable.name}) AS expense, '
      '(SELECT IFNULL(SUM(${SavingsBucketsTable.allocatedAmount}), 0) FROM ${SavingsBucketsTable.name}) AS allocated',
    );
    final _Row row = rows.first;
    return DashboardSummary.calculateFreeBalance(
      totalIncome: (row['income'] as num).toDouble(),
      totalExpense: (row['expense'] as num).toDouble(),
      totalAllocated: (row['allocated'] as num).toDouble(),
    );
  }

  static SavingsBucket _fromRow(_Row row) => SavingsBucket(
    id: row[SavingsBucketsTable.id] as int?,
    bucketName: row[SavingsBucketsTable.bucketName] as String,
    allocatedAmount: (row[SavingsBucketsTable.allocatedAmount] as num)
        .toDouble(),
    targetAmount:
        (row[SavingsBucketsTable.targetAmount] as num?)?.toDouble() ?? 0,
  );
}
