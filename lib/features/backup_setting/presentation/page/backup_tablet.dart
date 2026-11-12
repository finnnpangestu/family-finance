import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/page_header.dart';
import '../widgets/backup_widgets.dart';

class BackupTablet extends StatelessWidget {
  const BackupTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xxxl),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: PageHeader(title: 'Backup Google Drive'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
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
          ],
        ),
      ),
    );
  }
}
