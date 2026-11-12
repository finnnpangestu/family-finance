import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
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
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: const [
        _DashboardTopBar(),
        SizedBox(height: AppSpacing.lg),
        DashboardStatusBanner(),
        SummaryHeader(),
        SizedBox(height: AppSpacing.lg),
        IndicatorCard(kind: IndicatorKind.income),
        SizedBox(height: AppSpacing.sm),
        IndicatorCard(kind: IndicatorKind.expense),
        SizedBox(height: AppSpacing.sm),
        IndicatorCard(kind: IndicatorKind.balance),
        SizedBox(height: AppSpacing.xxl),
        _MenuHeading(),
        SizedBox(height: AppSpacing.md),
        DashboardQuickActions(),
      ],
    );
  }
}

// Inline top bar replacing AppBar — shows app name and date.
class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dateStr = '${now.day} ${bulan[now.month - 1]} ${now.year}';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keuangan',
                style: theme.typography.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: theme.typography.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.savings_outlined,
            color: Color(0xFFFFFFFF),
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _MenuHeading extends StatelessWidget {
  const _MenuHeading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Menu',
      style: theme.typography.h4.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.foreground,
      ),
    );
  }
}
