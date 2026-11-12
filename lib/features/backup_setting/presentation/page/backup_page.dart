import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'backup_mobile.dart';
import 'backup_tablet.dart';

// Entry point for Google Drive backup & restore.
class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup Google Drive')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= AppSpacing.tabletBreakpoint
              ? const BackupTablet()
              : const BackupMobile(),
        ),
      ),
    );
  }
}
