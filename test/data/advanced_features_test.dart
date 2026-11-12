import 'package:ff/core/database/app_database.dart';
import 'package:ff/core/database/database_providers.dart';
import 'package:ff/core/notifications/reminder_service.dart';
import 'package:ff/features/budget/data/budget_repository.dart';
import 'package:ff/features/budget/domain/budget_status.dart';
import 'package:ff/features/categories/data/category_repository.dart';
import 'package:ff/features/dashboard/data/finance_repository.dart';
import 'package:ff/features/dashboard/domain/models/expense.dart';
import 'package:ff/features/dashboard/domain/models/income.dart';
import 'package:ff/features/dashboard/domain/models/month_range.dart';
import 'package:ff/features/dashboard/presentation/controllers/transaction_actions.dart';
import 'package:ff/features/family_members/data/family_member_repository.dart';
import 'package:ff/features/recurring/data/recurring_repository.dart';
import 'package:ff/features/recurring/domain/recurring_rule.dart';
import 'package:ff/features/reminders/presentation/reminder_controller.dart';
import 'package:ff/features/report/data/monthly_report.dart';
import 'package:ff/features/transaction_history/data/history_repository.dart';
import 'package:ff/features/transaction_history/domain/history_filter.dart';
import 'package:ff/features/transaction_history/domain/transaction_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUpAll(() => initializeDateFormatting('id_ID'));
  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  final MonthRange may = MonthRange.of(DateTime(2026, 5));

  group('RecurringRule.nextDueAfter', () {
    test('keeps the day and clamps short months', () {
      expect(
        RecurringRule.nextDueAfter(DateTime(2026, 1, 31), 31),
        DateTime(2026, 2, 28),
      );
      expect(
        RecurringRule.nextDueAfter(DateTime(2026, 2, 28), 31),
        DateTime(2026, 3, 31),
      );
      expect(
        RecurringRule.nextDueAfter(DateTime(2028, 1, 30), 30),
        DateTime(2028, 2, 29),
      );
      expect(
        RecurringRule.nextDueAfter(DateTime(2026, 12, 5), 5),
        DateTime(2027, 1, 5),
      );
    });
  });

  group('RecurringRepository.generateDue', () {
    test('catches up missed months once and is idempotent', () async {
      final RecurringRepository repo = RecurringRepository(db);
      final int memberId = await FamilyMemberRepository(db).add('Ayah');
      await repo.create(
        RecurringRule(
          type: RecurringType.expense,
          categoryName: 'Tagihan',
          itemName: 'Listrik',
          amount: 300000,
          dayOfMonth: 10,
          nextDue: DateTime(2026, 3, 10),
          memberId: memberId,
        ),
      );
      await repo.create(
        RecurringRule(
          type: RecurringType.income,
          categoryName: 'Gaji Utama',
          amount: 5000000,
          dayOfMonth: 25,
          nextDue: DateTime(2026, 5, 25),
        ),
      );

      // 10 Mar, 10 Apr, 10 May; salary on the 25th is not due yet.
      expect(await repo.generateDue(DateTime(2026, 5, 20)), 3);
      expect(await repo.generateDue(DateTime(2026, 5, 20)), 0);

      final List<TransactionEntry> may2026 = await HistoryRepository(
        db,
      ).load(HistoryFilter(month: may));
      expect(may2026.single.title, 'Listrik');
      expect(may2026.single.memberName, 'Ayah');
      expect(may2026.single.isLumpsum, isFalse);

      final RecurringRule electricity = (await repo.list()).firstWhere(
        (r) => r.itemName == 'Listrik',
      );
      expect(electricity.nextDue, DateTime(2026, 6, 10));
    });

    test('paused rules are skipped', () async {
      final RecurringRepository repo = RecurringRepository(db);
      final int id = await repo.create(
        RecurringRule(
          type: RecurringType.expense,
          categoryName: Expense.lumpsumCategory,
          amount: 50000,
          dayOfMonth: 1,
          nextDue: DateTime(2026, 5, 1),
        ),
      );
      await repo.setActive(id, active: false);

      expect(await repo.generateDue(DateTime(2026, 5, 31)), 0);
    });
  });

  group('Budgets', () {
    test('status sums only the category and month', () async {
      final FinanceRepository finance = FinanceRepository(db);
      final BudgetRepository budgets = BudgetRepository(db);
      await budgets.upsert('Tagihan', 1000000);
      await finance.addItemizedExpenses(
        categoryName: 'Tagihan',
        date: DateTime(2026, 5, 3),
        items: const [ExpenseItemDraft(itemName: 'Air', amount: 850000)],
      );
      await finance.addItemizedExpenses(
        categoryName: 'Tagihan',
        date: DateTime(2026, 4, 3),
        items: const [ExpenseItemDraft(itemName: 'Air', amount: 999999)],
      );

      final BudgetStatus status = (await budgets.statusFor(may)).single;
      expect(status.spent, 850000);
      expect(status.level, BudgetLevel.warning);
      expect(status.remaining, 150000);
    });

    test('alerts only when a category moves to a worse level', () {
      BudgetStatus s(double spent) =>
          BudgetStatus(categoryName: 'Makan', limit: 100, spent: spent);

      expect(BudgetRepository.alertsBetween([s(50)], [s(79)]), isEmpty);
      expect(
        BudgetRepository.alertsBetween([s(50)], [s(85)]).single.status.level,
        BudgetLevel.warning,
      );
      expect(BudgetRepository.alertsBetween([s(85)], [s(90)]), isEmpty);
      expect(
        BudgetRepository.alertsBetween([s(85)], [s(120)]).single.status.level,
        BudgetLevel.over,
      );
    });

    test('saving an expense returns the alert it triggered', () async {
      final ProviderContainer c = ProviderContainer(
        overrides: [deviceDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(c.dispose);
      await BudgetRepository(db).upsert(Expense.lumpsumCategory, 100000);

      final TransactionActions actions = c.read(transactionActionsProvider);
      final List<BudgetAlert> first = await actions.addLumpsumExpense(
        amount: 50000,
        date: DateTime.now(),
      );
      final List<BudgetAlert> second = await actions.addLumpsumExpense(
        amount: 60000,
        date: DateTime.now(),
      );

      expect(first, isEmpty);
      expect(second.single.status.level, BudgetLevel.over);
      expect(second.single.message, contains('terlampaui'));
    });
  });

  group('Transaction actions', () {
    test('repeat monthly saves today and schedules next month', () async {
      final ProviderContainer c = ProviderContainer(
        overrides: [deviceDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(c.dispose);

      await c
          .read(transactionActionsProvider)
          .addIncome(
            Income(
              categoryName: 'Usaha Kue',
              amount: 750000,
              date: DateTime(2026, 1, 31),
            ),
            repeatMonthly: true,
          );

      final RecurringRule rule = (await RecurringRepository(db).list()).single;
      expect(rule.dayOfMonth, 31);
      expect(rule.nextDue, DateTime(2026, 2, 28));
      // Typing a new source in the form adds it to the category list.
      expect(
        await CategoryRepository(db).list(CategoryType.income),
        contains('Usaha Kue'),
      );
    });
  });

  group('Categories', () {
    test('defaults are seeded; add is idempotent; remove works', () async {
      final CategoryRepository repo = CategoryRepository(db);
      expect(await repo.list(CategoryType.income), [
        'Gaji Utama',
        'Usaha Sampingan',
      ]);

      await repo.add(CategoryType.expense, 'Sekolah Anak');
      await repo.add(CategoryType.expense, ' Sekolah Anak ');
      final List<String> expense = await repo.list(CategoryType.expense);
      expect(expense.where((n) => n == 'Sekolah Anak'), hasLength(1));

      await repo.remove(CategoryType.expense, 'Sekolah Anak');
      expect(
        await repo.list(CategoryType.expense),
        isNot(contains('Sekolah Anak')),
      );
    });
  });

  group('Family members', () {
    test('duplicates are rejected; removal unassigns history', () async {
      final FamilyMemberRepository members = FamilyMemberRepository(db);
      final int ibu = await members.add('Ibu');
      await expectLater(
        members.add('Ibu'),
        throwsA(isA<DuplicateMemberException>()),
      );
      await FinanceRepository(db).addIncome(
        Income(
          categoryName: 'Gaji Utama',
          amount: 1,
          date: DateTime(2026, 5, 2),
          memberId: ibu,
        ),
      );

      final HistoryRepository history = HistoryRepository(db);
      expect(
        await history.load(HistoryFilter(month: may, memberId: ibu)),
        hasLength(1),
      );

      await members.remove(ibu);
      final TransactionEntry entry = (await history.load(
        HistoryFilter(month: may),
      )).single;
      expect(entry.memberId, isNull);
      expect(entry.memberName, isNull);
    });
  });

  group('Monthly report', () {
    test('renders a PDF for a month with and without data', () async {
      final FinanceRepository finance = FinanceRepository(db);
      await finance.addIncome(
        Income(
          categoryName: 'Gaji Utama',
          amount: 5000000,
          date: DateTime(2026, 5, 1),
        ),
      );
      await finance.addLumpsumExpense(
        amount: 200000,
        date: DateTime(2026, 5, 2),
      );
      await BudgetRepository(db).upsert(Expense.lumpsumCategory, 150000);

      final MonthlyReportService service = MonthlyReportService(
        history: HistoryRepository(db),
        budgets: BudgetRepository(db),
      );
      final ReportFonts fonts = await ReportFonts.load();

      final MonthlyReportData data = await service.collect(may);
      expect(data.totalIncome, 5000000);
      expect(data.totalExpense, 200000);
      expect(data.budgets.single.level, BudgetLevel.over);

      for (final MonthRange month in [may, may.next]) {
        final bytes = await buildPdf(await service.collect(month), fonts);
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(1000));
      }
    });
  });

  group('Reminders', () {
    test('settings parse with safe defaults', () {
      expect(ReminderSettings.parse().timeLabel, '20:00');
      expect(ReminderSettings.parse(time: '07:30', daily: 'true').hour, 7);
      expect(ReminderSettings.parse(time: '99:00').hour, 20);
      expect(ReminderSettings.parse(budget: 'true').budgetAlertEnabled, isTrue);
    });

    test('daily time rolls over to tomorrow once passed', () {
      tzdata.initializeTimeZones();
      final tz.Location jakarta = tz.getLocation('Asia/Jakarta');
      final tz.TZDateTime morning = tz.TZDateTime(jakarta, 2026, 5, 1, 9);

      expect(
        ReminderService.nextInstanceOf(20, 0, morning),
        tz.TZDateTime(jakarta, 2026, 5, 1, 20),
      );
      expect(
        ReminderService.nextInstanceOf(8, 0, morning),
        tz.TZDateTime(jakarta, 2026, 5, 2, 8),
      );
    });
  });
}
