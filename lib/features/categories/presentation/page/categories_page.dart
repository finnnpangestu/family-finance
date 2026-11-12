import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/subpage_scaffold.dart';
import '../../data/category_repository.dart';

// Which list is being edited; page-local, so it resets on every visit.
final _selectedTypeProvider =
    NotifierProvider.autoDispose<_SelectedType, CategoryType>(
      _SelectedType.new,
    );

class _SelectedType extends AutoDisposeNotifier<CategoryType> {
  @override
  CategoryType build() => CategoryType.expense;

  void set(CategoryType type) => state = type;
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubpageScaffold(
      title: 'Kategori',
      subtitle: 'Pilihan cepat di form transaksi',
      children: [
        _TypeSwitcher(),
        SizedBox(height: AppSpacing.lg),
        _AddCategoryField(),
        SizedBox(height: AppSpacing.lg),
        _CategoryList(),
      ],
    );
  }
}

class _TypeSwitcher extends ConsumerWidget {
  const _TypeSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CategoryType type = ref.watch(_selectedTypeProvider);
    return SegmentedButton<CategoryType>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: CategoryType.expense,
          label: Text('Pengeluaran'),
          icon: Icon(FluentIcons.arrow_circle_up_24_regular),
        ),
        ButtonSegment(
          value: CategoryType.income,
          label: Text('Pemasukan'),
          icon: Icon(FluentIcons.arrow_circle_down_24_regular),
        ),
      ],
      selected: {type},
      onSelectionChanged: (s) =>
          ref.read(_selectedTypeProvider.notifier).set(s.first),
    );
  }
}

// Stateful only to own the text controller.
class _AddCategoryField extends ConsumerStatefulWidget {
  const _AddCategoryField();

  @override
  ConsumerState<_AddCategoryField> createState() => _AddCategoryFieldState();
}

class _AddCategoryFieldState extends ConsumerState<_AddCategoryField> {
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
      await ref
          .read(categoryRepositoryProvider)
          .add(ref.read(_selectedTypeProvider), name);
      ref.read(financeRevisionProvider.notifier).bump();
      _name.clear();
      if (mounted) {
        AppFeedback.showSuccess(context, 'Kategori "$name" ditambahkan');
      }
    } catch (error) {
      debugPrint('Add category failed: $error');
      if (mounted) AppFeedback.showError(context, 'Gagal menambah kategori');
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
            maxLength: 40,
            style: AppTypography.bodyLarge,
            onSubmitted: (_) => _add(),
            decoration: const InputDecoration(
              labelText: 'Kategori baru',
              hintText: 'Contoh: Sekolah Anak',
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
            icon: const Icon(FluentIcons.add_24_regular),
            label: const Text('Tambah'),
          ),
        ),
      ],
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList();

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    CategoryType type,
    String name,
  ) async {
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Hapus kategori "$name"?',
      message:
          'Kategori hilang dari pilihan cepat. Transaksi lama dengan kategori '
          'ini tidak terhapus.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(categoryRepositoryProvider).remove(type, name);
      ref.read(financeRevisionProvider.notifier).bump();
    } catch (error) {
      debugPrint('Remove category failed: $error');
      if (context.mounted) {
        AppFeedback.showError(context, 'Gagal menghapus kategori');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CategoryType type = ref.watch(_selectedTypeProvider);
    final List<String> names =
        ref
            .watch(
              type == CategoryType.income
                  ? incomeCategoriesProvider
                  : expenseCategoriesProvider,
            )
            .valueOrNull ??
        const [];

    if (names.isEmpty) {
      return Text(
        'Belum ada kategori. Tambahkan di atas.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }
    return Column(
      children: [
        for (final String name in names)
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
                  const Icon(
                    FluentIcons.tag_24_regular,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(name, style: AppTypography.bodyLarge)),
                  IconButton(
                    tooltip: 'Hapus $name',
                    color: AppColors.expense,
                    iconSize: 24,
                    onPressed: () => _remove(context, ref, type, name),
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
