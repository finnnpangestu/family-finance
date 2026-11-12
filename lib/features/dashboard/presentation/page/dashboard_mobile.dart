import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../budget/presentation/widgets/budget_card.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/cashflow_card.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_status_banner.dart';
import '../widgets/dashboard_top_bar.dart';
import '../widgets/income_streams_card.dart';

class DashboardMobile extends StatelessWidget {
  const DashboardMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: const [
        DashboardTopBar(logoSize: 44),
        SizedBox(height: AppSpacing.xl),
        DashboardStatusBanner(),
        BalanceHeroCard(),
        SizedBox(height: AppSpacing.lg),
        DashboardQuickActions(),
        SizedBox(height: AppSpacing.lg),
        CashflowCard(),
        SizedBox(height: AppSpacing.lg),
        BudgetCard(),
        SizedBox(height: AppSpacing.lg),
        IncomeStreamsCard(),
      ],
    );
  }
}
