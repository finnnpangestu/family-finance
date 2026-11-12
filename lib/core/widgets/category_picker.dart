import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_text_field.dart';

// Quick-pick chips that fill a free-text category field.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.controller,
    required this.options,
    required this.label,
    required this.requiredMessage,
  });

  final TextEditingController controller;
  final List<String> options;
  final String label;
  final String requiredMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: controller,
          label: label,
          hint: 'Pilih di bawah atau ketik baru',
          requiredMessage: requiredMessage,
        ),
        if (options.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          // Rebuilds only the chips when the text changes.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final String option in options)
                  _CategoryChip(
                    label: option,
                    selected: value.text.trim() == option,
                    onTap: () => controller.text = option,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: selected ? AppColors.onPrimary : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
