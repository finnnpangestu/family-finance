import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/savings_bucket.dart';
import '../controllers/savings_controller.dart';
import 'bucket_card.dart';

// Sliver of bucket cards in [columns] columns, with loading/error/empty states.
class BucketList extends ConsumerWidget {
  const BucketList({super.key, this.columns = 1});

  final int columns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<SavingsBucket> buckets = ref.watch(
      savingsControllerProvider.select((s) => s.buckets),
    );
    final bool isLoading = ref.watch(
      savingsControllerProvider.select((s) => s.isLoading),
    );
    final String? error = ref.watch(
      savingsControllerProvider.select((s) => s.errorMessage),
    );

    if (buckets.isEmpty) {
      final Widget placeholder;
      if (isLoading) {
        placeholder = const LoadingView();
      } else if (error != null) {
        placeholder = ErrorView(
          message: error,
          onRetry: () => ref.read(savingsControllerProvider.notifier).refresh(),
        );
      } else {
        placeholder = const EmptyView(
          icon: FluentIcons.savings_32_regular,
          message:
              'Belum ada pos tabungan.\nBuat pos seperti Dana Darurat atau Tabungan Sekolah.',
        );
      }
      return SliverToBoxAdapter(child: placeholder);
    }

    if (columns == 1) {
      return SliverList.separated(
        itemCount: buckets.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) =>
            BucketCard(key: ValueKey(buckets[i].id), bucket: buckets[i]),
      );
    }

    // Rows of [columns] cards keep heights natural without a fixed aspect ratio.
    final int rowCount = (buckets.length / columns).ceil();
    return SliverList.separated(
      itemCount: rowCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, row) {
        final int start = row * columns;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = start; i < start + columns; i++) ...[
                if (i > start) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: i < buckets.length
                      ? BucketCard(
                          key: ValueKey(buckets[i].id),
                          bucket: buckets[i],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
