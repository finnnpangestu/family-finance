import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import 'history_mobile.dart';
import 'history_tablet.dart';

// Entry point for transaction history (PRD F-05).
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: SafeArea(
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
