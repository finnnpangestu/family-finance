import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

// "Repeat every month on day X" toggle; the day follows the chosen date.
class RepeatMonthlySwitch extends StatelessWidget {
  const RepeatMonthlySwitch({
    super.key,
    required this.enabled,
    required this.date,
  });

  final ValueNotifier<bool> enabled;
  final ValueListenable<DateTime> date;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([enabled, date]),
      builder: (context, _) {
        final bool on = enabled.value;
        return Material(
          color: on ? AppColors.brandSurface : AppColors.muted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: () => enabled.value = !on,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.arrow_repeat_all_24_regular,
                    color: on ? AppColors.brandDark : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ulangi tiap bulan',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Otomatis dicatat setiap tanggal ${date.value.day}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: on,
                    activeThumbColor: AppColors.onPrimary,
                    activeTrackColor: AppColors.brand,
                    onChanged: (v) => enabled.value = v,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
