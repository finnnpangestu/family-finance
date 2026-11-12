import 'package:ff/core/database/app_database.dart';
import 'package:ff/core/database/database_providers.dart';
import 'package:ff/core/utils/app_feedback.dart';
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
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const FFApp(),
      ),
    );
    // sqflite FFI work happens outside the fake async zone.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
  }

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

    expect(find.text('Keuangan'), findsOneWidget);
    expect(find.text('Rp 2.500.000'), findsWidgets);
    expect(find.text('Tambah Transaksi'), findsOneWidget);
    expect(find.text('Riwayat Transaksi'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
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

    await tester.tap(find.text('Tambah Transaksi'));
    await tester.pumpAndSettle();

    expect(find.text('Pemasukan'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
  });
}
