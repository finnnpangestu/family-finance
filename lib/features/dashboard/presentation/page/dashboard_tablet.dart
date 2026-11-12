import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_status_banner.dart';
import '../widgets/indicator_card.dart';
import '../widgets/summary_header.dart';

// Two columns: financial summary left, actions right.
class DashboardTablet extends StatelessWidget {
  const DashboardTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.sm,
            AppSpacing.xxl,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DashboardStatusBanner(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SummaryHeader(),
                        SizedBox(height: AppSpacing.lg),
                        IndicatorCard(kind: IndicatorKind.income),
                        SizedBox(height: AppSpacing.md),
                        IndicatorCard(kind: IndicatorKind.expense),
                        SizedBox(height: AppSpacing.md),
                        IndicatorCard(kind: IndicatorKind.balance),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxl),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Menu', style: AppTypography.headingMedium),
                        const SizedBox(height: AppSpacing.md),
                        const DashboardQuickActions(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
