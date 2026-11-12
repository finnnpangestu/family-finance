import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

@immutable
class SubmitStatus {
  const SubmitStatus({this.isSubmitting = false, this.errorMessage});

  static const SubmitStatus idle = SubmitStatus();
  static const SubmitStatus submitting = SubmitStatus(isSubmitting: true);

  final bool isSubmitting;
  final String? errorMessage;
}

// Runs a form submission while guarding against double taps.
class SubmitController extends ValueNotifier<SubmitStatus> {
  SubmitController() : super(SubmitStatus.idle);

  Future<bool> run(
    Future<void> Function() task, {
    required String errorMessage,
    String? Function(Object error)? describeError,
  }) async {
    if (value.isSubmitting) return false;
    value = SubmitStatus.submitting;
    try {
      await task();
      value = SubmitStatus.idle;
      return true;
    } catch (error, stack) {
      debugPrint('Submit failed: $error\n$stack');
      value = SubmitStatus(
        errorMessage: describeError?.call(error) ?? errorMessage,
      );
      return false;
    }
  }
}

// Inline error + primary button; only this subtree rebuilds on status changes.
class FormSubmitArea extends StatelessWidget {
  const FormSubmitArea({
    super.key,
    required this.controller,
    required this.label,
    required this.onSubmit,
    this.icon,
    this.color,
  });

  final SubmitController controller;
  final String label;
  final VoidCallback onSubmit;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SubmitStatus>(
      valueListenable: controller,
      builder: (context, status, _) {
        final String? error = status.errorMessage;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  error,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.expense,
                  ),
                ),
              ),
            AppButton(
              label: label,
              icon: icon,
              color: color,
              isLoading: status.isSubmitting,
              onPressed: onSubmit,
            ),
          ],
        );
      },
    );
  }
}
