import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/subpage_scaffold.dart';
import '../../data/family_member_repository.dart';
import '../../domain/family_member.dart';

class FamilyMembersPage extends StatelessWidget {
  const FamilyMembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubpageScaffold(
      title: 'Anggota Keluarga',
      subtitle: 'Tandai transaksi milik siapa',
      children: [
        _AddMemberField(),
        SizedBox(height: AppSpacing.lg),
        _MemberList(),
      ],
    );
  }
}

// Stateful only to own the text controller.
class _AddMemberField extends ConsumerStatefulWidget {
  const _AddMemberField();

  @override
  ConsumerState<_AddMemberField> createState() => _AddMemberFieldState();
}

class _AddMemberFieldState extends ConsumerState<_AddMemberField> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final String name = _name.text.trim();
    if (name.isEmpty) return;
    try {
      await ref.read(familyMemberRepositoryProvider).add(name);
      ref.read(financeRevisionProvider.notifier).bump();
      _name.clear();
      if (mounted) AppFeedback.showSuccess(context, '$name ditambahkan');
    } on DuplicateMemberException {
      if (mounted) AppFeedback.showError(context, '$name sudah ada');
    } catch (error) {
      debugPrint('Add member failed: $error');
      if (mounted) AppFeedback.showError(context, 'Gagal menambah anggota');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 30,
            style: AppTypography.bodyLarge,
            onSubmitted: (_) => _add(),
            decoration: const InputDecoration(
              labelText: 'Nama anggota',
              hintText: 'Contoh: Ayah, Ibu, Kakak',
              counterText: '',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          height: AppSpacing.buttonHeight,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            onPressed: _add,
            icon: const Icon(FluentIcons.person_add_24_regular),
            label: const Text('Tambah'),
          ),
        ),
      ],
    );
  }
}

class _MemberList extends ConsumerWidget {
  const _MemberList();

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
  ) async {
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Hapus ${member.name}?',
      message:
          'Transaksi milik ${member.name} tidak terhapus, hanya tidak lagi '
          'ditandai atas namanya.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(familyMemberRepositoryProvider).remove(member.id);
      ref.read(financeRevisionProvider.notifier).bump();
    } catch (error) {
      debugPrint('Remove member failed: $error');
      if (context.mounted) {
        AppFeedback.showError(context, 'Gagal menghapus anggota');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<FamilyMember> members =
        ref.watch(familyMembersProvider).valueOrNull ?? const [];
    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(
          'Belum ada anggota. Setelah ditambahkan, Anda bisa memilih anggota '
          'saat mencatat transaksi dan menyaring riwayat per anggota.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final FamilyMember member in members)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.listItemMinHeight,
              ),
              padding: const EdgeInsets.only(left: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.brandSurface,
                    child: Text(
                      member.name.characters.first.toUpperCase(),
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.brandDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(member.name, style: AppTypography.bodyLarge),
                  ),
                  IconButton(
                    tooltip: 'Hapus ${member.name}',
                    color: AppColors.expense,
                    onPressed: () => _remove(context, ref, member),
                    icon: const Icon(FluentIcons.delete_24_regular),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
