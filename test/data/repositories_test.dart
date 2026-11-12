import 'package:ff/core/database/app_database.dart';
import 'package:ff/features/dashboard/data/finance_repository.dart';
import 'package:ff/features/dashboard/domain/models/dashboard_summary.dart';
import 'package:ff/features/dashboard/domain/models/expense.dart';
import 'package:ff/features/dashboard/domain/models/income.dart';
import 'package:ff/features/dashboard/domain/models/month_range.dart';
import 'package:ff/features/savings_bucket/data/savings_repository.dart';
import 'package:ff/features/savings_bucket/domain/savings_bucket.dart';
import 'package:ff/features/transaction_history/data/history_repository.dart';
import 'package:ff/features/transaction_history/domain/history_filter.dart';
import 'package:ff/features/transaction_history/domain/transaction_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FinanceRepository finance;
  late SavingsRepository savings;
  late HistoryRepository history;

  final MonthRange may = MonthRange.of(DateTime(2026, 5));

  setUp(() {
    db = createTestDatabase();
    finance = FinanceRepository(db);
    savings = SavingsRepository(db);
    history = HistoryRepository(db);
  });

  tearDown(() => db.close());

  Future<void> seed() async {
    await finance.addIncome(
      Income(
        categoryName: 'Gaji Utama',
        amount: 5000000,
        date: DateTime(2026, 5, 1),
      ),
    );
    await finance.addIncome(
      Income(
        categoryName: 'Usaha Sampingan',
        amount: 1500000,
        date: DateTime(2026, 5, 10),
      ),
    );
    // Previous month: counts toward free balance only.
    await finance.addIncome(
      Income(
        categoryName: 'Gaji Utama',
        amount: 1000000,
        date: DateTime(2026, 4, 30),
      ),
    );
    await finance.addLumpsumExpense(amount: 300000, date: DateTime(2026, 5, 5));
    await finance.addItemizedExpenses(
      categoryName: 'Tagihan',
      date: DateTime(2026, 5, 31),
      items: const [
        ExpenseItemDraft(itemName: 'Listrik', amount: 100000),
        ExpenseItemDraft(itemName: 'Air', amount: 100000),
      ],
    );
  }

  group('FinanceRepository', () {
    test('summary adds income streams A + B for the month', () async {
      await seed();
      final DashboardSummary summary = await finance.loadSummary(may);

      expect(summary.monthIncome, 6500000);
      expect(summary.incomeStreams.map((s) => s.categoryName), [
        'Gaji Utama',
        'Usaha Sampingan',
      ]);
      expect(summary.monthExpense, 500000);
      expect(summary.freeBalance, 7500000 - 500000);
    });

    test('empty database yields zero summary', () async {
      final DashboardSummary summary = await finance.loadSummary(may);
      expect(summary, DashboardSummary.empty);
    });

    test('itemized expenses with no items are rejected', () async {
      await expectLater(
        finance.addItemizedExpenses(
          categoryName: 'X',
          items: const [],
          date: DateTime(2026),
        ),
        throwsArgumentError,
      );
    });

    test('categories are ordered by usage', () async {
      await seed();
      expect(await finance.incomeCategories(), [
        'Gaji Utama',
        'Usaha Sampingan',
      ]);
      expect(await finance.itemizedExpenseCategories(), ['Tagihan']);
    });
  });

  group('SavingsRepository', () {
    test('allocation reduces free balance and is capped by it', () async {
      await finance.addIncome(
        Income(
          categoryName: 'Gaji Utama',
          amount: 1000000,
          date: DateTime(2026, 5, 1),
        ),
      );
      final int id = await savings.create(
        name: 'Dana Darurat',
        targetAmount: 2000000,
      );

      await savings.allocate(id, 400000);
      expect(await savings.freeBalance(), 600000);
      expect((await finance.loadSummary(may)).freeBalance, 600000);

      await expectLater(
        savings.allocate(id, 600001),
        throwsA(isA<SavingsRuleException>()),
      );
      expect((await savings.getAll()).single.allocatedAmount, 400000);
    });

    test('withdraw is capped by bucket content; delete frees funds', () async {
      await finance.addIncome(
        Income(
          categoryName: 'Gaji Utama',
          amount: 1000000,
          date: DateTime(2026, 5, 1),
        ),
      );
      final int id = await savings.create(name: 'Tabungan A', targetAmount: 0);
      await savings.allocate(id, 500000);

      await expectLater(
        savings.withdraw(id, 500001),
        throwsA(isA<SavingsRuleException>()),
      );
      await savings.withdraw(id, 200000);
      expect(await savings.freeBalance(), 700000);

      await savings.delete(id);
      expect(await savings.freeBalance(), 1000000);
    });

    test('bucket progress is clamped', () {
      const SavingsBucket bucket = SavingsBucket(
        bucketName: 'A',
        allocatedAmount: 300,
        targetAmount: 200,
      );
      expect(bucket.progress, 1.0);
      expect(bucket.isTargetReached, isTrue);
      expect(
        const SavingsBucket(bucketName: 'B', allocatedAmount: 50).progress,
        0,
      );
    });
  });

  group('HistoryRepository', () {
    test('lists incomes and expenses of the month newest first', () async {
      await seed();
      final List<TransactionEntry> entries = await history.load(
        HistoryFilter(month: may),
      );

      expect(entries, hasLength(5));
      expect(entries.first.date, DateTime(2026, 5, 31));
      expect(entries.where((e) => e.isIncome), hasLength(2));
      expect(
        entries.firstWhere((e) => e.itemName == 'Listrik').categoryName,
        'Tagihan',
      );
      expect(
        entries.firstWhere((e) => e.isLumpsum).categoryName,
        Expense.lumpsumCategory,
      );
    });

    test('filters by category and exposes month categories', () async {
      await seed();
      final List<TransactionEntry> bills = await history.load(
        HistoryFilter(month: may, category: 'Tagihan'),
      );
      expect(bills.map((e) => e.title), unorderedEquals(['Listrik', 'Air']));

      expect(await history.categories(may), [
        'Gaji Utama',
        Expense.lumpsumCategory,
        'Tagihan',
        'Usaha Sampingan',
      ]);
    });

    test('spending chart groups expenses per category', () async {
      await seed();
      final List<CategorySpending> spending = await history.spendingByCategory(
        may,
      );
      expect(spending, const [
        CategorySpending(categoryName: Expense.lumpsumCategory, amount: 300000),
        CategorySpending(categoryName: 'Tagihan', amount: 200000),
      ]);
    });
  });

  group('MonthRange', () {
    test('handles year boundaries', () {
      final MonthRange december = MonthRange.of(DateTime(2025, 12, 15));
      expect(december.next.start, DateTime(2026));
      expect(december.next.previous, december);
      expect(december.contains(DateTime(2025, 12, 31)), isTrue);
      expect(december.contains(DateTime(2026)), isFalse);
    });
  });
}
