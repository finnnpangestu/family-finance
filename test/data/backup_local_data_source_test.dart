import 'dart:convert';

import 'package:ff/core/database/app_database.dart';
import 'package:ff/features/backup_setting/data/backup_local_data_source.dart';
import 'package:ff/features/backup_setting/domain/backup_models.dart';
import 'package:ff/features/dashboard/data/finance_repository.dart';
import 'package:ff/features/dashboard/domain/models/expense.dart';
import 'package:ff/features/dashboard/domain/models/income.dart';
import 'package:ff/features/dashboard/domain/models/month_range.dart';
import 'package:ff/features/savings_bucket/data/savings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase source;
  late AppDatabase target;

  setUp(() {
    source = createTestDatabase();
    target = createTestDatabase();
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  Matcher invalidFile() => throwsA(
    isA<BackupException>().having(
      (e) => e.kind,
      'kind',
      BackupFailureKind.invalidFile,
    ),
  );

  test('export then restore reproduces the same data', () async {
    final FinanceRepository finance = FinanceRepository(source);
    await finance.addIncome(
      Income(
        categoryName: 'Gaji Utama',
        amount: 4000000,
        date: DateTime(2026, 5, 1),
        note: 'Mei',
      ),
    );
    await finance.addItemizedExpenses(
      categoryName: 'Tagihan',
      date: DateTime(2026, 5, 2),
      items: const [ExpenseItemDraft(itemName: 'Listrik', amount: 150000)],
    );
    final int bucket = await SavingsRepository(
      source,
    ).create(name: 'Darurat', targetAmount: 1000000);
    await SavingsRepository(source).allocate(bucket, 250000);

    // Pre-existing target data must be replaced, not merged.
    await FinanceRepository(
      target,
    ).addLumpsumExpense(amount: 999, date: DateTime(2020));

    final List<int> bytes = await BackupLocalDataSource(source).exportBytes();
    await BackupLocalDataSource(target).restoreBytes(bytes);

    final MonthRange may = MonthRange.of(DateTime(2026, 5));
    expect(
      await FinanceRepository(target).loadSummary(may),
      await finance.loadSummary(may),
    );
    expect(
      await SavingsRepository(target).getAll(),
      await SavingsRepository(source).getAll(),
    );
  });

  test('rejects files that are not FF backups', () {
    expect(
      () => BackupLocalDataSource.parse(utf8.encode('not json')),
      invalidFile(),
    );
    expect(
      () => BackupLocalDataSource.parse(
        utf8.encode(jsonEncode({'app': 'other'})),
      ),
      invalidFile(),
    );
  });

  test('rejects backups from a newer schema version', () {
    final List<int> bytes = utf8.encode(
      jsonEncode({
        'app': BackupLocalDataSource.appId,
        'schemaVersion': AppDatabase.schemaVersion + 1,
        'tables': <String, Object?>{},
      }),
    );
    expect(() => BackupLocalDataSource.parse(bytes), invalidFile());
  });

  test('ignores unknown columns', () {
    final List<int> bytes = utf8.encode(
      jsonEncode({
        'app': BackupLocalDataSource.appId,
        'schemaVersion': AppDatabase.schemaVersion,
        'tables': {
          'incomes': [
            {
              'id': 1,
              'category_name': 'A',
              'amount': 1,
              'date': '2026-01-01',
              'evil': 'x',
            },
          ],
        },
      }),
    );
    final Map<String, List<Map<String, Object?>>> parsed =
        BackupLocalDataSource.parse(bytes);
    expect(parsed['incomes']!.single.containsKey('evil'), isFalse);
    expect(parsed['expenses'], isEmpty);
  });

  test('failed restore leaves local data untouched', () async {
    await FinanceRepository(
      target,
    ).addLumpsumExpense(amount: 777, date: DateTime(2026, 5, 3));
    // Missing NOT NULL columns make the insert fail inside the transaction.
    final List<int> bytes = utf8.encode(
      jsonEncode({
        'app': BackupLocalDataSource.appId,
        'schemaVersion': AppDatabase.schemaVersion,
        'tables': {
          'incomes': [
            {'id': 1, 'category_name': 'A'},
          ],
        },
      }),
    );

    await expectLater(
      BackupLocalDataSource(target).restoreBytes(bytes),
      throwsA(anything),
    );
    final summary = await FinanceRepository(
      target,
    ).loadSummary(MonthRange.of(DateTime(2026, 5)));
    expect(summary.monthExpense, 777);
  });
}
