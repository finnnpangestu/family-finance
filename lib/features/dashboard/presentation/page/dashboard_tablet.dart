import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_status_banner.dart';
import '../widgets/indicator_card.dart';
import '../widgets/summary_header.dart';

// Two columns: financial summary left, actions right.
class DashboardTablet extends StatelessWidget {
  const DashboardTablet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Inline top bar
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Keuangan',
                      style: theme.typography.h2.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.savings_outlined,
                      color: Color(0xFFFFFFFF),
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
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
                        SizedBox(height: AppSpacing.sm),
                        IndicatorCard(kind: IndicatorKind.expense),
                        SizedBox(height: AppSpacing.sm),
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
                        Text(
                          'Menu',
                          style: theme.typography.h4.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
