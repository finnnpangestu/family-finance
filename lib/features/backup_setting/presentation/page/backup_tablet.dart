import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../widgets/backup_widgets.dart';

class BackupTablet extends StatelessWidget {
  const BackupTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: const SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.sm,
            AppSpacing.xxl,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BackupMessageBanner(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BackupAccountCard(),
                        SizedBox(height: AppSpacing.lg),
                        BackupInfoCard(),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.xxl),
                  Expanded(child: BackupActionsCard()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
