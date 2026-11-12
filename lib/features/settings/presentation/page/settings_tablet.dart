import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/page_header.dart';
import '../widgets/settings_menu.dart';

// A single readable column; a long option list gains nothing from two panes.
class SettingsTablet extends StatelessWidget {
  const SettingsTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          children: const [
            PageHeader(title: 'Pengaturan'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: SettingsMenu(),
            ),
          ],
        ),
      ),
    );
  }
}
