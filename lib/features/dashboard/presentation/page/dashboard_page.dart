import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'dashboard_mobile.dart';
import 'dashboard_tablet.dart';

// App home and the only navigation hub (PRD F-01).
// DashboardController loads itself on first read by the widgets below.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keuangan Keluarga')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= AppSpacing.tabletBreakpoint
              ? const DashboardTablet()
              : const DashboardMobile(),
        ),
      ),
    );
  }
}
