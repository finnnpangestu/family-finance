import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/monthly_cashflow.dart';

// Grouped bars (income vs expense) per month on a single shared axis.
// Tap or drag across the plot to select a month.
class CashflowChart extends StatelessWidget {
  const CashflowChart({
    super.key,
    required this.data,
    required this.selectedIndex,
    required this.onSelect,
    this.height = 200,
  });

  final List<MonthlyCashflow> data;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final double height;

  static final DateFormat _monthShort = DateFormat('MMM', 'id_ID');
  static final DateFormat _monthLong = DateFormat('MMMM yyyy', 'id_ID');

  void _selectAt(double dx, double width) {
    final int index = _ChartGeometry.indexAt(dx, width, data.length);
    if (index != selectedIndex) onSelect(index);
  }

  // Text alternative for screen readers: every value, month by month.
  String get _semanticSummary => [
    'Grafik arus kas ${data.length} bulan.',
    for (final MonthlyCashflow m in data)
      '${_monthLong.format(m.month)}: pemasukan '
          '${CurrencyFormatter.format(m.income)}, pengeluaran '
          '${CurrencyFormatter.format(m.expense)}.',
  ].join(' ');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticSummary,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _selectAt(d.localPosition.dx, width),
            onHorizontalDragUpdate: (d) => _selectAt(d.localPosition.dx, width),
            child: TweenAnimationBuilder<double>(
              // Bars grow from the baseline on first paint.
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) => CustomPaint(
                size: Size(width, height),
                painter: _CashflowPainter(
                  data: data,
                  selectedIndex: selectedIndex,
                  progress: progress,
                  monthLabels: [
                    for (final m in data) _monthShort.format(m.month),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

abstract final class _ChartGeometry {
  static const double axisWidth = 52;
  static const double labelHeight = 28;
  static const double topPadding = 8;

  static int indexAt(double dx, double width, int count) {
    final double slot = (width - axisWidth) / count;
    return ((dx - axisWidth) / slot).floor().clamp(0, count - 1);
  }

  // Rounds the max up to 2 "nice" steps so gridlines land on round numbers.
  static double niceStep(double maxValue) {
    if (maxValue <= 0) return 1;
    final double half = maxValue / 2;
    final double magnitude = math
        .pow(10, (math.log(half) / math.ln10).floor())
        .toDouble();
    for (final double f in const [1, 2, 2.5, 5, 10]) {
      if (f * magnitude >= half) return f * magnitude;
    }
    return 10 * magnitude;
  }
}

class _CashflowPainter extends CustomPainter {
  _CashflowPainter({
    required this.data,
    required this.selectedIndex,
    required this.progress,
    required this.monthLabels,
  });

  final List<MonthlyCashflow> data;
  final int selectedIndex;
  final double progress;
  final List<String> monthLabels;

  static const double _barGap = 2;
  static const double _maxBarWidth = 16;
  static const Radius _barRadius = Radius.circular(4);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const double left = _ChartGeometry.axisWidth;
    final double plotWidth = size.width - left;
    final double plotHeight =
        size.height - _ChartGeometry.labelHeight - _ChartGeometry.topPadding;
    final double baseline = _ChartGeometry.topPadding + plotHeight;
    final double slot = plotWidth / data.length;

    final double maxValue = data.fold<double>(
      0,
      (m, d) => math.max(m, math.max(d.income, d.expense)),
    );
    final double step = _ChartGeometry.niceStep(maxValue);
    final double top = step * 2;

    // Selected month band sits behind everything else.
    canvas.drawRRect(
      RRect.fromLTRBR(
        left + slot * selectedIndex + 2,
        0,
        left + slot * (selectedIndex + 1) - 2,
        size.height,
        const Radius.circular(10),
      ),
      Paint()..color = AppColors.muted,
    );

    // Recessive gridlines with compact labels (0, step, 2·step).
    final Paint grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (int i = 0; i <= 2; i++) {
      final double y = baseline - plotHeight * (i / 2);
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      _text(
        canvas,
        i == 0 ? '0' : CurrencyFormatter.compact(step * i),
        AppTypography.caption.copyWith(color: AppColors.textSecondary),
        Offset(left - 8, y),
        align: _Align.rightCenter,
      );
    }

    final double barWidth = math.min(_maxBarWidth, slot * 0.26);
    final Paint incomePaint = Paint()..color = AppColors.chartIncome;
    final Paint expensePaint = Paint()..color = AppColors.chartExpense;

    for (int i = 0; i < data.length; i++) {
      final double center = left + slot * i + slot / 2;
      _bar(
        canvas,
        center - _barGap / 2 - barWidth,
        barWidth,
        baseline,
        _height(data[i].income, top, plotHeight),
        incomePaint,
      );
      _bar(
        canvas,
        center + _barGap / 2,
        barWidth,
        baseline,
        _height(data[i].expense, top, plotHeight),
        expensePaint,
      );

      final bool selected = i == selectedIndex;
      _text(
        canvas,
        monthLabels[i],
        AppTypography.caption.copyWith(
          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        Offset(center, baseline + 6),
        align: _Align.topCenter,
      );
    }
  }

  double _height(double value, double top, double plotHeight) {
    if (value <= 0) return 0;
    // Keep tiny but non-zero values visible.
    return math.max(2, value / top * plotHeight) * progress;
  }

  // Rounded data-end on top, flat on the baseline.
  void _bar(
    Canvas canvas,
    double x,
    double width,
    double baseline,
    double height,
    Paint paint,
  ) {
    if (height <= 0) return;
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        x,
        baseline - height,
        x + width,
        baseline,
        topLeft: _barRadius,
        topRight: _barRadius,
      ),
      paint,
    );
  }

  void _text(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset anchor, {
    required _Align align,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final Offset origin = switch (align) {
      _Align.rightCenter => anchor - Offset(painter.width, painter.height / 2),
      _Align.topCenter => anchor - Offset(painter.width / 2, 0),
    };
    painter.paint(canvas, origin);
    painter.dispose();
  }

  @override
  bool shouldRepaint(_CashflowPainter old) =>
      old.data != data ||
      old.selectedIndex != selectedIndex ||
      old.progress != progress;
}

enum _Align { rightCenter, topCenter }
