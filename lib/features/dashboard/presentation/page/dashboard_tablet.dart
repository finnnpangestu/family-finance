import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../budget/presentation/widgets/budget_card.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/cashflow_card.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_status_banner.dart';
import '../widgets/dashboard_top_bar.dart';
import '../widgets/income_streams_card.dart';

// Two columns: balance + actions + income streams left, cashflow chart right.
class DashboardTablet extends StatelessWidget {
  const DashboardTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: const SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardTopBar(),
              SizedBox(height: AppSpacing.xl),
              DashboardStatusBanner(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BalanceHeroCard(),
                        SizedBox(height: AppSpacing.lg),
                        DashboardQuickActions(),
                        SizedBox(height: AppSpacing.lg),
                        IncomeStreamsCard(),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.xxl),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CashflowCard(chartHeight: 320),
                        SizedBox(height: AppSpacing.lg),
                        BudgetCard(),
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
