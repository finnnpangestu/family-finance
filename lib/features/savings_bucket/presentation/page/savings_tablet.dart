import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/page_header.dart';
import '../widgets/bucket_list.dart';
import '../widgets/savings_forms.dart';
import '../widgets/savings_overview.dart';

class SavingsTablet extends StatelessWidget {
  const SavingsTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageHeader(title: 'Pos Tabungan'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(flex: 2, child: SavingsOverview()),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: AppButton(
                            label: 'Buat Pos Baru',
                            icon: FluentIcons.add_24_regular,
                            color: AppColors.savings,
                            onPressed: () => openCreateBucketSheet(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                0,
                AppSpacing.xxl,
                AppSpacing.xxxl,
              ),
              sliver: BucketList(columns: 2),
            ),
          ],
        ),
      ),
    );
  }
}
