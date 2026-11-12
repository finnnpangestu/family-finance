import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/bucket_list.dart';
import '../widgets/savings_forms.dart';
import '../widgets/savings_overview.dart';

class SavingsMobile extends StatelessWidget {
  const SavingsMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SavingsOverview(),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Buat Pos Baru',
                  icon: FluentIcons.add_24_regular,
                  color: AppColors.savings,
                  onPressed: () => openCreateBucketSheet(context),
                ),
              ],
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          sliver: BucketList(),
        ),
      ],
    );
  }
}
