import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../widgets/backup_widgets.dart';

class BackupMobile extends StatelessWidget {
  const BackupMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: const [
        BackupMessageBanner(),
        BackupAccountCard(),
        SizedBox(height: AppSpacing.lg),
        BackupActionsCard(),
        SizedBox(height: AppSpacing.lg),
        BackupInfoCard(),
      ],
    );
  }
}
