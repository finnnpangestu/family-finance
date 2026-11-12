import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import 'savings_mobile.dart';
import 'savings_tablet.dart';

// Entry point for savings buckets (PRD F-04).
class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: SafeArea(
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
