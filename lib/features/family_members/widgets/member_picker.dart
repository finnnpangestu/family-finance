import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/family_member_repository.dart';
import '../domain/family_member.dart';

// Optional "who is this for" chips; hidden until members exist.
class MemberPicker extends ConsumerWidget {
  const MemberPicker({super.key, required this.selected});

  // null = unassigned.
  final ValueNotifier<int?> selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<FamilyMember> members =
        ref.watch(familyMembersProvider).valueOrNull ?? const [];
    if (members.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anggota keluarga (opsional)',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ValueListenableBuilder<int?>(
            valueListenable: selected,
            builder: (context, current, _) => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _Chip(
                  label: 'Semua / umum',
                  selected: current == null,
                  onTap: () => selected.value = null,
                ),
                for (final FamilyMember member in members)
                  _Chip(
                    label: member.name,
                    selected: current == member.id,
                    onTap: () => selected.value = member.id,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.card,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
        width: 1.5,
      ),
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: selected ? AppColors.onPrimary : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
