import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/subpage_scaffold.dart';
import '../reminder_controller.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubpageScaffold(
      title: 'Pengingat',
      subtitle: 'Notifikasi di HP ini, tanpa internet',
      children: [_ReminderOptions()],
    );
  }
}

class _ReminderOptions extends ConsumerWidget {
  const _ReminderOptions();

  // Runs a change and turns failures into a readable message.
  Future<void> _apply(
    BuildContext context,
    Future<void> Function() change,
  ) async {
    try {
      await change();
    } on NotificationPermissionDenied {
      if (context.mounted) {
        AppFeedback.showError(
          context,
          'Izin notifikasi ditolak. Aktifkan lewat Pengaturan HP.',
        );
      }
    } catch (error) {
      debugPrint('Reminder change failed: $error');
      if (context.mounted) {
        AppFeedback.showError(context, 'Gagal menyimpan pengingat');
      }
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    ReminderSettings current,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Jam pengingat',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null || !context.mounted) return;
    await _apply(
      context,
      () => ref
          .read(reminderControllerProvider.notifier)
          .setTime(picked.hour, picked.minute),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ReminderSettings> value = ref.watch(
      reminderControllerProvider,
    );
    final ReminderSettings? settings = value.valueOrNull;
    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final ReminderController controller = ref.read(
      reminderControllerProvider.notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OptionCard(
          icon: FluentIcons.alert_24_regular,
          title: 'Pengingat harian',
          description: 'Diingatkan mencatat pengeluaran setiap hari.',
          value: settings.dailyEnabled,
          onChanged: (v) =>
              _apply(context, () => controller.setDailyEnabled(v)),
          footer: settings.dailyEnabled
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      AppSpacing.minTouchTarget,
                    ),
                  ),
                  onPressed: () => _pickTime(context, ref, settings),
                  icon: const Icon(FluentIcons.clock_24_regular),
                  label: Text('Jam ${settings.timeLabel} · Ubah'),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        _OptionCard(
          icon: FluentIcons.warning_24_regular,
          title: 'Peringatan anggaran',
          description:
              'Notifikasi saat pengeluaran mencapai 80% atau melebihi '
              'anggaran kategori.',
          value: settings.budgetAlertEnabled,
          onChanged: (v) =>
              _apply(context, () => controller.setBudgetAlertEnabled(v)),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final Widget? bottom = footer;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textPrimary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                activeThumbColor: AppColors.onPrimary,
                activeTrackColor: AppColors.brand,
                onChanged: onChanged,
              ),
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: AppSpacing.md),
            bottom,
          ],
        ],
      ),
    );
  }
}
