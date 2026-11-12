import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/subpage_scaffold.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurring_rule.dart';

class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubpageScaffold(
      title: 'Transaksi Rutin',
      subtitle: 'Dicatat otomatis setiap bulan',
      children: [
        _HowToNote(),
        SizedBox(height: AppSpacing.lg),
        _RuleList(),
      ],
    );
  }
}

class _HowToNote extends StatelessWidget {
  const _HowToNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.brandSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            FluentIcons.info_20_regular,
            size: 20,
            color: AppColors.brandDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Untuk menambah, nyalakan "Ulangi tiap bulan" saat mencatat '
              'pemasukan atau pengeluaran. Transaksi dibuat saat aplikasi '
              'dibuka pada atau setelah tanggalnya.',
              style: AppTypography.caption.copyWith(color: AppColors.brandDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleList extends ConsumerWidget {
  const _RuleList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RecurringRule>> rules = ref.watch(
      recurringRulesProvider,
    );
    final List<RecurringRule> list = rules.valueOrNull ?? const [];
    if (rules.isLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return Text(
        'Belum ada transaksi rutin.',
        style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
      );
    }
    return Column(
      children: [for (final RecurringRule rule in list) _RuleCard(rule: rule)],
    );
  }
}

class _RuleCard extends ConsumerWidget {
  const _RuleCard({required this.rule});

  final RecurringRule rule;

  Future<void> _setActive(
    BuildContext context,
    WidgetRef ref,
    bool active,
  ) async {
    final int? id = rule.id;
    if (id == null) return;
    try {
      await ref.read(recurringRepositoryProvider).setActive(id, active: active);
      ref.read(financeRevisionProvider.notifier).bump();
    } catch (error) {
      debugPrint('Toggle recurring failed: $error');
      if (context.mounted) AppFeedback.showError(context, 'Gagal menyimpan');
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final int? id = rule.id;
    if (id == null) return;
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Hapus "${rule.title}"?',
      message:
          'Tidak akan dicatat lagi bulan depan. Transaksi yang sudah tercatat '
          'tetap ada di riwayat.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(recurringRepositoryProvider).remove(id);
      ref.read(financeRevisionProvider.notifier).bump();
    } catch (error) {
      debugPrint('Remove recurring failed: $error');
      if (context.mounted) AppFeedback.showError(context, 'Gagal menghapus');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool income = rule.type == RecurringType.income;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Opacity(
        // Paused rules stay readable but clearly secondary.
        opacity: rule.active ? 1 : 0.6,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    income
                        ? FluentIcons.arrow_circle_down_24_regular
                        : FluentIcons.arrow_circle_up_24_regular,
                    color: income ? AppColors.income : AppColors.expense,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.title,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Tiap tanggal ${rule.dayOfMonth} · '
                          '${CurrencyFormatter.format(rule.amount)}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: rule.active,
                    activeThumbColor: AppColors.onPrimary,
                    activeTrackColor: AppColors.brand,
                    onChanged: (v) => _setActive(context, ref, v),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rule.active
                          ? 'Berikutnya: ${DateFormatter.medium(rule.nextDue)}'
                          : 'Dijeda',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.expense,
                      minimumSize: const Size(0, AppSpacing.minTouchTarget),
                    ),
                    onPressed: () => _remove(context, ref),
                    icon: const Icon(FluentIcons.delete_20_regular),
                    label: const Text('Hapus'),
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
