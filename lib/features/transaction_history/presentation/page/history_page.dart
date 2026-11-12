import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'history_mobile.dart';
import 'history_tablet.dart';

// Entry point for transaction history (PRD F-05).
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= AppSpacing.tabletBreakpoint
              ? const HistoryTablet()
              : const HistoryMobile(),
        ),
      ),
    );
  }
}
