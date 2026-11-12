import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

// Wraps shadcn TextField inside a Material TextFormField shell so that
// Form / FormState validation still works across the existing forms.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.requiredMessage,
    this.textInputAction = TextInputAction.next,
    this.maxLength = 60,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;

  // When set, empty input fails validation with this message.
  final String? requiredMessage;
  final TextInputAction textInputAction;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: textInputAction,
      maxLength: maxLength,
      style: AppTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: const Color(0xFF475569),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: const Color(0xFF94A3B8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Color(0xFF991B1B), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Color(0xFF991B1B), width: 2),
        ),
      ),
      validator: (value) {
        final String? message = requiredMessage;
        if (message != null && (value == null || value.trim().isEmpty)) {
          return message;
        }
        return null;
      },
    );
  }
}
