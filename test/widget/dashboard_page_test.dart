import 'package:ff/core/database/app_database.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:ff/core/database/database_providers.dart';
import 'package:ff/core/settings/app_currency.dart';
import 'package:ff/core/settings/settings_store.dart';
import 'package:ff/core/utils/app_feedback.dart';
import 'package:ff/core/utils/currency_formatter.dart';
import 'package:ff/features/settings/presentation/page/settings_page.dart';
import 'package:ff/features/settings/presentation/widgets/settings_menu.dart';
import 'package:ff/core/utils/date_formatter.dart';
import 'package:ff/features/dashboard/presentation/widgets/cashflow_chart.dart';
import 'package:ff/features/dashboard/presentation/widgets/dashboard_top_bar.dart';
import 'package:ff/features/dashboard/presentation/page/dashboard_page.dart';
import 'package:ff/features/dashboard/data/finance_repository.dart';
import 'package:ff/features/dashboard/domain/models/income.dart';
import 'package:ff/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID');
  });

  // Open outside the fake-async zone so FFI futures can complete.
  setUp(() async {
    db = createTestDatabase();
    await db.database;
  });
  tearDown(() async {
    // The formatter is app-global; keep tests independent.
    CurrencyFormatter.use(AppCurrency.idr);
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [deviceDatabaseProvider.overrideWithValue(db)],
        child: const FFApp(),
      ),
    );
    // sqflite FFI work happens outside the fake async zone.
    await settle(tester);
  }

  testWidgets('changing currency in Settings updates the dashboard', (
    tester,
  ) async {
    await tester.runAsync(
      () => FinanceRepository(db).addIncome(
        Income(
          categoryName: 'Gaji Utama',
          amount: 2500000,
          date: DateTime.now(),
        ),
      ),
    );
    await pumpApp(tester, const Size(400, 1000));
    expect(find.text('Rp 2.500.000'), findsWidgets);

    await tester.tap(find.byIcon(FluentIcons.settings_24_regular));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mata Uang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dolar Amerika'));
    await settle(tester);

    expect(CurrencyFormatter.currency.code, 'USD');
    expect(
      await tester.runAsync(
        () => SettingsStore(db).read(SettingsStore.currencyCode),
      ),
      'USD',
    );

    // Back on the dashboard, already-built text shows the new symbol.
    // Back twice: currency page, then the settings menu.
    Navigator.of(tester.element(find.byType(CurrencyPage))).pop();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(SettingsPage))).pop();
    await tester.pumpAndSettle();
    expect(find.text(r'$ 2.500.000'), findsWidgets);
    expect(find.text('Rp 2.500.000'), findsNothing);
    // Let the confirmation toast time out.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('mobile dashboard shows total income and quick actions', (
    tester,
  ) async {
    await tester.runAsync(
      () => FinanceRepository(db).addIncome(
        Income(
          categoryName: 'Gaji Utama',
          amount: 2500000,
          date: DateTime.now(),
        ),
      ),
    );
    await pumpApp(tester, const Size(400, 900));

    expect(find.text(DashboardTopBar.greeting(DateTime.now())), findsOneWidget);
    expect(find.text('Rp 2.500.000'), findsWidgets);
    expect(find.text('Tambah'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('cashflow chart switches the readout when a month is tapped', (
    tester,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime oldest = DateTime(now.year, now.month - 5, 10);
    await tester.runAsync(() async {
      final FinanceRepository repo = FinanceRepository(db);
      await repo.addIncome(
        Income(categoryName: 'Gaji Utama', amount: 4000000, date: now),
      );
      await repo.addLumpsumExpense(amount: 1250000, date: oldest);
    });
    await pumpApp(tester, const Size(400, 1600));

    // Defaults to the current month: income shown, expense zero.
    expect(find.text('Rp 4.000.000'), findsWidgets);
    expect(find.text('Arus Kas'), findsOneWidget);

    final Rect chart = tester.getRect(find.byType(CashflowChart));
    // First month column starts right after the 52px y-axis gutter.
    await tester.tapAt(Offset(chart.left + 60, chart.center.dy));
    await tester.pumpAndSettle();

    expect(find.text(DateFormatter.monthYear(oldest)), findsOneWidget);
    expect(find.text('Rp 1.250.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet dashboard lays out without overflow', (tester) async {
    await pumpApp(tester, const Size(1024, 768));

    expect(find.text('Pos Tabungan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Regression: pages use shadcn Scaffold, so a Material SnackBar used to crash.
  testWidgets('feedback toast shows on a page without Material Scaffold', (
    tester,
  ) async {
    await pumpApp(tester, const Size(400, 900));

    AppFeedback.showSuccess(
      tester.element(find.byType(DashboardPage)),
      'Pemasukan berhasil disimpan',
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.text('Pemasukan berhasil disimpan'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('add transaction opens the type chooser sheet', (tester) async {
    await pumpApp(tester, const Size(400, 900));

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Pemasukan'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
  });
}
