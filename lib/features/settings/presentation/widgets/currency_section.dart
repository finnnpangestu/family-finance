import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_currency.dart';
import '../../../../core/settings/currency_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_feedback.dart';

class CurrencySection extends StatelessWidget {
  const CurrencySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.incomeSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  FluentIcons.money_24_regular,
                  color: AppColors.income,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('Mata Uang', style: AppTypography.headingMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  FluentIcons.info_20_regular,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Hanya mengganti simbol yang ditampilkan. Nominal yang '
                    'sudah dicatat tidak dikonversi kursnya.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final AppCurrency currency in AppCurrency.supported)
            _CurrencyOption(currency: currency),
        ],
      ),
    );
  }
}

// Only the tiles whose selected flag flips rebuild on change.
class _CurrencyOption extends ConsumerWidget {
  const _CurrencyOption({required this.currency});

  final AppCurrency currency;

  Future<void> _select(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(currencyControllerProvider.notifier).select(currency);
      if (context.mounted) {
        AppFeedback.showSuccess(
          context,
          'Mata uang diganti ke ${currency.name}',
        );
      }
    } catch (error) {
      debugPrint('Currency change failed: $error');
      if (context.mounted) {
        AppFeedback.showError(context, 'Gagal menyimpan mata uang');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool selected = ref.watch(
      currencyControllerProvider.select((c) => c == currency),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        selected: selected,
        button: true,
        label: '${currency.name}, ${currency.code}',
        excludeSemantics: true,
        child: Material(
          color: selected ? AppColors.muted : AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: selected ? null : () => _select(context, ref),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.listItemMinHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.muted,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          currency.symbol,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.onPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currency.name,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            currency.code,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(
                        FluentIcons.checkmark_circle_24_regular,
                        color: AppColors.income,
                        size: 28,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
