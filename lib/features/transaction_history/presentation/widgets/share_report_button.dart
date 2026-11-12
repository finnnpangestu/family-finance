import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../dashboard/domain/models/month_range.dart';
import '../../../report/data/monthly_report.dart';
import '../controllers/history_controller.dart';

// Shares a PDF of the month currently shown in the history.
// Stateful only for the local "building PDF" spinner.
class ShareReportButton extends ConsumerStatefulWidget {
  const ShareReportButton({super.key});

  @override
  ConsumerState<ShareReportButton> createState() => _ShareReportButtonState();
}

class _ShareReportButtonState extends ConsumerState<ShareReportButton> {
  final ValueNotifier<bool> _busy = ValueNotifier(false);

  @override
  void dispose() {
    _busy.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_busy.value) return;
    _busy.value = true;
    final MonthRange month = ref.read(historyControllerProvider).filter.month;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Rect? origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      await ref.read(monthlyReportServiceProvider).share(month, origin: origin);
    } catch (error, stack) {
      debugPrint('Report share failed: $error\n$stack');
      if (mounted) AppFeedback.showError(context, 'Gagal membuat laporan');
    } finally {
      if (mounted) _busy.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _busy,
      builder: (context, busy, _) => Semantics(
        button: true,
        label: 'Bagikan laporan bulan ini',
        excludeSemantics: true,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brandDark,
            minimumSize: const Size(0, AppSpacing.minTouchTarget),
            side: const BorderSide(color: AppColors.border, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          onPressed: busy ? null : _share,
          icon: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(FluentIcons.share_android_24_regular),
          label: const Text('Bagikan'),
        ),
      ),
    );
  }
}
