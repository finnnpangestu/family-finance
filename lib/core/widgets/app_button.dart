import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

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
    final Widget child = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
      isOutline: variant == AppButtonVariant.outline,
    );

    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: switch (variant) {
        AppButtonVariant.outline => OutlineButton(
          onPressed: action,
          child: child,
        ),
        AppButtonVariant.destructive => DestructiveButton(
          onPressed: action,
          child: child,
        ),
        AppButtonVariant.primary => _ColoredPrimaryButton(
          color: color,
          onPressed: action,
          child: child,
        ),
      },
    );
  }
}

// Wraps PrimaryButton but overrides fill color when provided.
class _ColoredPrimaryButton extends StatelessWidget {
  const _ColoredPrimaryButton({
    required this.child,
    required this.onPressed,
    this.color,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (color == null) {
      return PrimaryButton(onPressed: onPressed, child: child);
    }
    // Provide a custom-colored filled button container.
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: AppSpacing.buttonHeight,
        decoration: BoxDecoration(
          color: onPressed == null ? color!.withValues(alpha: 0.5) : color!,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.isOutline,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isOutline;

  @override
  Widget build(BuildContext context) {
    final Color loaderColor = isOutline
        ? AppColors.primary
        : AppColors.onPrimary;
    final IconData? leading = icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: loaderColor,
            ),
          )
        else if (leading != null)
          Icon(leading, size: 20),
        if (isLoading || leading != null) const SizedBox(width: 8),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
