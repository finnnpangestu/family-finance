import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import 'dashboard_mobile.dart';
import 'dashboard_tablet.dart';

// App home and the only navigation hub (PRD F-01).
// No AppBar — modern design uses an inline header inside the scroll content.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: SafeArea(
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
