import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/backup_models.dart';
import '../controllers/backup_controller.dart';

class BackupAccountCard extends ConsumerWidget {
  const BackupAccountCard({super.key});

  // The user decides, since on a shared phone the records may be someone else's.
  static Future<bool> _askMoveDeviceData(
    BuildContext context,
    String accountName,
  ) async {
    if (!context.mounted) return false;
    return AppFeedback.confirm(
      context,
      title: 'Pindahkan catatan ke akun ini?',
      message:
          'Ada catatan keuangan yang tersimpan di HP ini tanpa akun. '
          'Pindahkan ke akun $accountName? Pilih "Batal" untuk memulai '
          'akun ini dengan catatan kosong; catatan HP ini tetap tersimpan.',
      confirmLabel: 'Pindahkan',
    );
  }

  static Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Keluar dari akun?',
      message:
          'Catatan akun ini tetap tersimpan di HP dan akan muncul lagi saat '
          'Anda masuk kembali. Setelah keluar, aplikasi menampilkan catatan '
          'HP ini (tanpa akun).',
      confirmLabel: 'Keluar',
    );
    if (confirmed) await ref.read(backupControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BackupAccount? account = ref.watch(
      backupControllerProvider.select((s) => s.account),
    );
    final BackupBusy busy = ref.watch(
      backupControllerProvider.select((s) => s.busy),
    );
    final BackupController controller = ref.read(
      backupControllerProvider.notifier,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(FluentIcons.person_circle_32_regular, size: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: busy == BackupBusy.checking
                      ? Text(
                          'Memeriksa akun...',
                          style: AppTypography.bodyLarge,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account?.displayName ?? 'Akun Google',
                              style: AppTypography.headingMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              account?.email ?? 'Belum masuk',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (account == null)
              AppButton(
                label: 'Masuk dengan Google',
                icon: FluentIcons.person_24_regular,
                isLoading: busy == BackupBusy.signingIn,
                onPressed: busy == BackupBusy.none
                    ? () => controller.signIn(
                        askMoveDeviceData: (name) =>
                            _askMoveDeviceData(context, name),
                      )
                    : null,
              )
            else
              AppButton(
                label: 'Keluar Akun',
                icon: FluentIcons.sign_out_24_regular,
                variant: AppButtonVariant.outline,
                isLoading: busy == BackupBusy.signingOut,
                onPressed: busy == BackupBusy.none
                    ? () => _signOut(context, ref)
                    : null,
              ),
            const SizedBox(height: AppSpacing.md),
            const _DataOwnerNote(),
          ],
        ),
      ),
    );
  }
}

// Makes it explicit whose records are on screen right now.
class _DataOwnerNote extends ConsumerWidget {
  const _DataOwnerNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AccountProfile? profile = ref.watch(activeAccountProvider);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            FluentIcons.database_20_regular,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              profile == null
                  ? 'Catatan yang tampil: tersimpan di HP ini (tanpa akun).'
                  : 'Catatan yang tampil: milik ${profile.email}.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BackupActionsCard extends ConsumerWidget {
  const BackupActionsCard({super.key});

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Pulihkan data?',
      message:
          'Semua data di HP ini akan diganti dengan data dari backup '
          'Google Drive. Tindakan ini tidak bisa dibatalkan.',
      confirmLabel: 'Pulihkan',
      destructive: true,
    );
    if (confirmed) await ref.read(backupControllerProvider.notifier).restore();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool signedIn = ref.watch(
      backupControllerProvider.select((s) => s.isSignedIn),
    );
    final BackupBusy busy = ref.watch(
      backupControllerProvider.select((s) => s.busy),
    );
    final bool idle = busy == BackupBusy.none;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Backup & Pulihkan', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.xs),
            const _LastBackupText(),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Backup Sekarang',
              icon: FluentIcons.cloud_arrow_up_24_regular,
              color: AppColors.savings,
              isLoading: busy == BackupBusy.backingUp,
              onPressed: signedIn && idle
                  ? ref.read(backupControllerProvider.notifier).backup
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Pulihkan dari Drive',
              icon: FluentIcons.cloud_arrow_down_24_regular,
              variant: AppButtonVariant.outline,
              isLoading: busy == BackupBusy.restoring,
              onPressed: signedIn && idle ? () => _restore(context, ref) : null,
            ),
            if (!signedIn) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Masuk dengan akun Google terlebih dahulu.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LastBackupText extends ConsumerWidget {
  const _LastBackupText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BackupInfo? info = ref.watch(
      backupControllerProvider.select((s) => s.lastBackup),
    );
    final bool signedIn = ref.watch(
      backupControllerProvider.select((s) => s.isSignedIn),
    );
    final DateTime? time = info?.modifiedTime;

    final String text;
    if (!signedIn) {
      text = 'Status backup tampil setelah masuk.';
    } else if (time == null) {
      text = 'Belum ada backup.';
    } else {
      final String clock =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      text = 'Backup terakhir: ${DateFormatter.medium(time)}, $clock';
    }
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
    );
  }
}

// Result of the last action; tap the close icon to dismiss.
class BackupMessageBanner extends ConsumerWidget {
  const BackupMessageBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BackupMessage? message = ref.watch(
      backupControllerProvider.select((s) => s.message),
    );
    if (message == null) return const SizedBox.shrink();
    final Color color = message.isError ? AppColors.expense : AppColors.income;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Material(
        color: message.isError
            ? AppColors.expenseSurface
            : AppColors.incomeSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.lg),
          child: Row(
            children: [
              Icon(
                message.isError
                    ? FluentIcons.warning_24_regular
                    : FluentIcons.checkmark_circle_24_regular,
                color: color,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    message.text,
                    style: AppTypography.bodyMedium.copyWith(color: color),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                color: color,
                onPressed: ref
                    .read(backupControllerProvider.notifier)
                    .clearMessage,
                icon: const Icon(FluentIcons.dismiss_24_regular),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BackupInfoCard extends StatelessWidget {
  const BackupInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.savingsSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            FluentIcons.shield_checkmark_24_regular,
            color: AppColors.savings,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Backup disimpan di folder khusus aplikasi pada Google Drive Anda '
              'sendiri. Tidak terlihat di Drive dan tidak bisa dibuka aplikasi lain. '
              'Tanpa biaya server.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.savings,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
