import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/page_header.dart';
import '../widgets/backup_widgets.dart';

class BackupMobile extends StatelessWidget {
  const BackupMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xxxl),
      children: const [
        PageHeader(title: 'Backup Google Drive'),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BackupMessageBanner(),
              BackupAccountCard(),
              SizedBox(height: AppSpacing.lg),
              BackupActionsCard(),
              SizedBox(height: AppSpacing.lg),
              BackupInfoCard(),
            ],
          ),
        ),
      ],
    );
  }
}
