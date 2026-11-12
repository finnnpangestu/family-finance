import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/page_header.dart';
import '../widgets/settings_menu.dart';

class SettingsMobile extends StatelessWidget {
  const SettingsMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: const [
        PageHeader(title: 'Pengaturan'),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SettingsMenu(),
        ),
      ],
    );
  }
}
