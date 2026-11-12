import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/currency_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/subpage_scaffold.dart';
import '../../../budget/presentation/page/budget_page.dart';
import '../../../categories/presentation/page/categories_page.dart';
import '../../../family_members/presentation/page/family_members_page.dart';
import '../../../recurring/presentation/page/recurring_page.dart';
import '../../../reminders/presentation/page/reminders_page.dart';
import 'currency_section.dart';

// Settings entry list; each row opens its own page.
class SettingsMenu extends ConsumerWidget {
  const SettingsMenu({super.key});

  static void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String currency = ref.watch(
      currencyControllerProvider.select((c) => '${c.name} (${c.symbol})'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GroupLabel('Keuangan'),
        _MenuTile(
          icon: FluentIcons.target_arrow_24_regular,
          title: 'Anggaran',
          subtitle: 'Batas pengeluaran per kategori',
          onTap: () => _open(context, const BudgetPage()),
        ),
        _MenuTile(
          icon: FluentIcons.arrow_repeat_all_24_regular,
          title: 'Transaksi Rutin',
          subtitle: 'Tagihan & pemasukan bulanan otomatis',
          onTap: () => _open(context, const RecurringPage()),
        ),
        _MenuTile(
          icon: FluentIcons.tag_24_regular,
          title: 'Kategori',
          subtitle: 'Tambah atau hapus kategori',
          onTap: () => _open(context, const CategoriesPage()),
        ),
        const SizedBox(height: AppSpacing.md),
        const _GroupLabel('Keluarga & Aplikasi'),
        _MenuTile(
          icon: FluentIcons.people_24_regular,
          title: 'Anggota Keluarga',
          subtitle: 'Ayah, Ibu, anak, dan lainnya',
          onTap: () => _open(context, const FamilyMembersPage()),
        ),
        _MenuTile(
          icon: FluentIcons.alert_24_regular,
          title: 'Pengingat',
          subtitle: 'Notifikasi harian & peringatan anggaran',
          onTap: () => _open(context, const RemindersPage()),
        ),
        _MenuTile(
          icon: FluentIcons.money_24_regular,
          title: 'Mata Uang',
          subtitle: currency,
          onTap: () => _open(context, const CurrencyPage()),
        ),
      ],
    );
  }
}

class CurrencyPage extends StatelessWidget {
  const CurrencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubpageScaffold(
      title: 'Mata Uang',
      children: [CurrencySection()],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.listItemMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brandSurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(icon, color: AppColors.brandDark),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    FluentIcons.chevron_right_24_regular,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
