import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  // Primary call-to-action gets the dark fill.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final Color foreground = highlighted
        ? AppColors.onPrimary
        : AppColors.textPrimary;
    final Color secondary = highlighted
        ? AppColors.border
        : AppColors.textSecondary;

    return Material(
      color: highlighted ? AppColors.primary : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: highlighted
            ? BorderSide.none
            : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                Icon(icon, size: 32, color: foreground),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: AppTypography.bodyLarge.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        description,
                        style: AppTypography.caption.copyWith(color: secondary),
                      ),
                    ],
                  ),
                ),
                Icon(FluentIcons.chevron_right_24_regular, color: secondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
