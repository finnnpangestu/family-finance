import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/savings_bucket.dart';
import '../controllers/savings_controller.dart';
import 'savings_forms.dart';

class BucketCard extends ConsumerWidget {
  const BucketCard({super.key, required this.bucket});

  final SavingsBucket bucket;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final int? id = bucket.id;
    if (id == null) return;
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Hapus ${bucket.bucketName}?',
      message: bucket.allocatedAmount > 0
          ? 'Isi pos ${CurrencyFormatter.format(bucket.allocatedAmount)} '
                'akan kembali ke saldo bebas.'
          : 'Pos ini akan dihapus.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(savingsControllerProvider.notifier).delete(id);
      if (context.mounted) {
        AppFeedback.showSuccess(context, 'Pos tabungan dihapus');
      }
    } catch (_) {
      if (context.mounted) {
        AppFeedback.showError(context, 'Gagal menghapus pos tabungan');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  FluentIcons.savings_32_regular,
                  size: 32,
                  color: AppColors.savings,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    bucket.bucketName,
                    style: AppTypography.headingMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus pos',
                  color: AppColors.expense,
                  iconSize: 24,
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(FluentIcons.delete_24_regular),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.format(bucket.allocatedAmount),
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.savings,
                ),
              ),
            ),
            if (bucket.hasTarget) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: LinearProgressIndicator(
                  value: bucket.progress,
                  minHeight: 10,
                  color: bucket.isTargetReached
                      ? AppColors.income
                      : AppColors.savings,
                  backgroundColor: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                bucket.isTargetReached
                    ? 'Target tercapai!'
                    : '${(bucket.progress * 100).floor()}% dari '
                          '${CurrencyFormatter.format(bucket.targetAmount)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Isi',
                    icon: FluentIcons.add_24_regular,
                    color: AppColors.savings,
                    onPressed: () => openFundSheet(
                      context,
                      bucket: bucket,
                      isWithdraw: false,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    label: 'Ambil',
                    icon: FluentIcons.arrow_undo_24_regular,
                    variant: AppButtonVariant.outline,
                    onPressed: bucket.allocatedAmount > 0
                        ? () => openFundSheet(
                            context,
                            bucket: bucket,
                            isWithdraw: true,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
