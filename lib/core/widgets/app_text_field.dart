import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

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
