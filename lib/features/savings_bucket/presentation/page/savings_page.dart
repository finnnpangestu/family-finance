import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'savings_mobile.dart';
import 'savings_tablet.dart';

// Entry point for savings buckets (PRD F-04).
class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pos Tabungan')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= AppSpacing.tabletBreakpoint
              ? const SavingsTablet()
              : const SavingsMobile(),
        ),
      ),
    );
  }
}
