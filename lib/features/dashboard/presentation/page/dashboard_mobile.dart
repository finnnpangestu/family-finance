import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_status_banner.dart';
import '../widgets/indicator_card.dart';
import '../widgets/summary_header.dart';

class DashboardMobile extends StatelessWidget {
  const DashboardMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        const DashboardStatusBanner(),
        const SummaryHeader(),
        const SizedBox(height: AppSpacing.lg),
        const IndicatorCard(kind: IndicatorKind.income),
        const SizedBox(height: AppSpacing.md),
        const IndicatorCard(kind: IndicatorKind.expense),
        const SizedBox(height: AppSpacing.md),
        const IndicatorCard(kind: IndicatorKind.balance),
        const SizedBox(height: AppSpacing.xxl),
        Text('Menu', style: AppTypography.headingMedium),
        const SizedBox(height: AppSpacing.md),
        const DashboardQuickActions(),
      ],
    );
  }
}
