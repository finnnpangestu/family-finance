import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../backup_setting/presentation/page/backup_page.dart';
import '../../../savings_bucket/presentation/page/savings_page.dart';
import '../../../transaction_history/presentation/page/history_page.dart';
import 'add_transaction_flow.dart';

// Single-hub navigation as a 4-up action grid; replaces any bottom nav bar.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ActionTile(
            icon: FluentIcons.add_24_regular,
            label: 'Tambah Transaksi',
            primary: true,
            onTap: () => openAddTransactionFlow(context),
          ),
        ),
        Expanded(
          child: _ActionTile(
            icon: FluentIcons.history_24_regular,
            label: 'Riwayat',
            onTap: () => _push(context, const HistoryPage()),
          ),
        ),
        Expanded(
          child: _ActionTile(
            icon: FluentIcons.savings_24_regular,
            label: 'Pos Tabungan',
            onTap: () => _push(context, const SavingsPage()),
          ),
        ),
        Expanded(
          child: _ActionTile(
            icon: FluentIcons.cloud_arrow_up_24_regular,
            label: 'Backup Drive',
            onTap: () => _push(context, const BackupPage()),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: ConstrainedBox(
            // Whole tile is the touch target, well above 48dp.
            constraints: const BoxConstraints(minHeight: 104),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: primary ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: primary
                          ? null
                          : Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: primary
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: primary
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
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
