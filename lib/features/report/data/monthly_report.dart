import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../budget/data/budget_repository.dart';
import '../../budget/domain/budget_status.dart';
import '../../dashboard/domain/models/month_range.dart';
import '../../transaction_history/data/history_repository.dart';
import '../../transaction_history/domain/history_filter.dart';
import '../../transaction_history/domain/transaction_entry.dart';

// Everything one monthly report shows, gathered before rendering.
class MonthlyReportData {
  const MonthlyReportData({
    required this.month,
    required this.entries,
    required this.spending,
    required this.budgets,
  });

  final MonthRange month;
  final List<TransactionEntry> entries;
  final List<CategorySpending> spending;
  final List<BudgetStatus> budgets;

  double get totalIncome =>
      entries.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);

  double get totalExpense =>
      entries.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);
}

final monthlyReportServiceProvider = Provider<MonthlyReportService>(
  (ref) => MonthlyReportService(
    history: ref.watch(historyRepositoryProvider),
    budgets: ref.watch(budgetRepositoryProvider),
  ),
);

class MonthlyReportService {
  const MonthlyReportService({
    required HistoryRepository history,
    required BudgetRepository budgets,
  }) : _history = history,
       _budgets = budgets;

  final HistoryRepository _history;
  final BudgetRepository _budgets;

  Future<MonthlyReportData> collect(MonthRange month) async =>
      MonthlyReportData(
        month: month,
        entries: await _history.load(HistoryFilter(month: month)),
        spending: await _history.spendingByCategory(month),
        budgets: await _budgets.statusFor(month),
      );

  // Renders to a temp file and opens the platform share sheet. [origin] is
  // required on iPad, where the sheet is a popover anchored to the button.
  Future<void> share(MonthRange month, {Rect? origin}) async {
    final MonthlyReportData data = await collect(month);
    final Uint8List bytes = await buildPdf(data, await ReportFonts.load());
    final Directory dir = await getTemporaryDirectory();
    final String key = DateFormatter.toStorage(month.start).substring(0, 7);
    final File file = File(p.join(dir.path, 'Laporan-FF-$key.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    final String title =
        'Laporan Keuangan ${DateFormatter.monthYear(month.start)}';
    await SharePlus.instance.share(
      ShareParams(
        title: title,
        subject: title,
        text: '$title — dibuat dengan FF (Family Finance).',
        files: [XFile(file.path, mimeType: 'application/pdf')],
        sharePositionOrigin: origin,
      ),
    );
  }
}

// Brand font so Indonesian text and "Rp" render the same as in the app.
class ReportFonts {
  const ReportFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;

  static Future<ReportFonts> load() async => ReportFonts(
    regular: pw.Font.ttf(
      await rootBundle.load('assets/google_fonts/PlusJakartaSans-Regular.ttf'),
    ),
    bold: pw.Font.ttf(
      await rootBundle.load('assets/google_fonts/PlusJakartaSans-Bold.ttf'),
    ),
  );
}

// Pure rendering step: same data in, same PDF out (kept testable).
Future<Uint8List> buildPdf(MonthlyReportData data, ReportFonts fonts) {
  const PdfColor ink = PdfColor.fromInt(0xFF1A1D24);
  const PdfColor teal = PdfColor.fromInt(0xFF00787C);
  const PdfColor red = PdfColor.fromInt(0xFF991B1B);
  const PdfColor muted = PdfColor.fromInt(0xFF4A5260);
  const PdfColor line = PdfColor.fromInt(0xFFDDE4E4);
  const PdfColor band = PdfColor.fromInt(0xFFEEF2F2);

  final String monthLabel = DateFormatter.monthYear(data.month.start);
  final double net = data.totalIncome - data.totalExpense;
  final pw.TextStyle h2 = pw.TextStyle(
    font: fonts.bold,
    fontSize: 14,
    color: ink,
  );

  pw.Widget figure(String label, double value, PdfColor color) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: line),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: muted)),
          pw.SizedBox(height: 4),
          pw.Text(
            CurrencyFormatter.format(value),
            style: pw.TextStyle(font: fonts.bold, fontSize: 13, color: color),
          ),
        ],
      ),
    ),
  );

  // Amount columns ([right]) are right-aligned so digits line up.
  pw.Widget table(
    List<String> headers,
    List<List<String>> rows, {
    required Set<int> right,
  }) => pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(font: fonts.bold, fontSize: 10),
    cellStyle: const pw.TextStyle(fontSize: 10),
    headerDecoration: const pw.BoxDecoration(color: band),
    border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: line)),
    cellAlignments: {for (final int i in right) i: pw.Alignment.centerRight},
    headerAlignments: {for (final int i in right) i: pw.Alignment.centerRight},
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
  );

  final pw.Document doc = pw.Document(
    title: 'Laporan Keuangan $monthLabel',
    creator: 'FF - Family Finance',
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Halaman ${context.pageNumber} dari ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: muted),
        ),
      ),
      build: (context) => [
        pw.Text(
          'Laporan Keuangan Keluarga',
          style: pw.TextStyle(font: fonts.bold, fontSize: 20, color: ink),
        ),
        pw.Text(
          '$monthLabel · dibuat ${DateFormatter.long(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: muted),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          children: [
            figure('Pemasukan', data.totalIncome, teal),
            pw.SizedBox(width: 8),
            figure('Pengeluaran', data.totalExpense, red),
            pw.SizedBox(width: 8),
            figure(net >= 0 ? 'Surplus' : 'Defisit', net, ink),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text('Pengeluaran per Kategori', style: h2),
        pw.SizedBox(height: 6),
        if (data.spending.isEmpty)
          pw.Text(
            'Tidak ada pengeluaran.',
            style: const pw.TextStyle(color: muted),
          )
        else
          table(
            ['Kategori', 'Jumlah', 'Porsi'],
            [
              for (final CategorySpending s in data.spending)
                [
                  s.categoryName,
                  CurrencyFormatter.format(s.amount),
                  data.totalExpense == 0
                      ? '-'
                      : '${(s.amount / data.totalExpense * 100).round()}%',
                ],
            ],
            right: {1, 2},
          ),
        if (data.budgets.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text('Anggaran', style: h2),
          pw.SizedBox(height: 6),
          table(
            ['Kategori', 'Terpakai', 'Batas', 'Status'],
            [
              for (final BudgetStatus b in data.budgets)
                [
                  b.categoryName,
                  CurrencyFormatter.format(b.spent),
                  CurrencyFormatter.format(b.limit),
                  switch (b.level) {
                    BudgetLevel.safe => 'Aman',
                    BudgetLevel.warning => 'Hampir habis',
                    BudgetLevel.over => 'Melebihi',
                  },
                ],
            ],
            right: {1, 2},
          ),
        ],
        pw.SizedBox(height: 20),
        pw.Text('Daftar Transaksi (${data.entries.length})', style: h2),
        pw.SizedBox(height: 6),
        if (data.entries.isEmpty)
          pw.Text(
            'Tidak ada transaksi bulan ini.',
            style: const pw.TextStyle(color: muted),
          )
        else
          table(
            ['Tanggal', 'Keterangan', 'Anggota', 'Jumlah'],
            [
              for (final TransactionEntry e in data.entries)
                [
                  DateFormatter.medium(e.date),
                  e.itemName == null
                      ? e.categoryName
                      : '${e.itemName} (${e.categoryName})',
                  e.memberName ?? '-',
                  '${e.isIncome ? '+' : '-'}${CurrencyFormatter.format(e.amount)}',
                ],
            ],
            right: {3},
          ),
      ],
    ),
  );
  return doc.save();
}
