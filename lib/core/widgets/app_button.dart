import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, outline, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;

  // Overrides the primary fill color, e.g. income green.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? action = isLoading ? null : onPressed;
    final Widget content = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
      loaderColor: variant == AppButtonVariant.outline
          ? AppColors.primary
          : AppColors.onPrimary,
    );
    final ButtonStyle base = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size.fromHeight(AppSpacing.buttonHeight),
      ),
      textStyle: WidgetStatePropertyAll(
        AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );

    switch (variant) {
      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: action,
          style: base.merge(
            OutlinedButton.styleFrom(
              foregroundColor: color ?? AppColors.primary,
              side: const BorderSide(color: AppColors.border, width: 1.5),
            ),
          ),
          child: content,
        );
      case AppButtonVariant.primary:
      case AppButtonVariant.destructive:
        final Color fill = variant == AppButtonVariant.destructive
            ? AppColors.expense
            : color ?? AppColors.primary;
        return FilledButton(
          onPressed: action,
          style: base.merge(
            FilledButton.styleFrom(
              backgroundColor: fill,
              foregroundColor: AppColors.onPrimary,
              disabledBackgroundColor: fill.withValues(alpha: 0.5),
              disabledForegroundColor: AppColors.onPrimary,
            ),
          ),
          child: content,
        );
    }
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.loaderColor,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color loaderColor;

  @override
  Widget build(BuildContext context) {
    final IconData? leading = icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: loaderColor,
            ),
          )
        else if (leading != null)
          Icon(leading, size: 24),
        if (isLoading || leading != null) const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
