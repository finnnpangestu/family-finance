import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import 'settings_mobile.dart';
import 'settings_tablet.dart';

// App preferences, opened from the gear icon on the dashboard.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= AppSpacing.tabletBreakpoint
              ? const SettingsTablet()
              : const SettingsMobile(),
        ),
      ),
    );
  }
}
