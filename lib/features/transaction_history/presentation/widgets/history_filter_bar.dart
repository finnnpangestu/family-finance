import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../dashboard/domain/models/month_range.dart';
import '../controllers/history_controller.dart';

// Month switcher plus horizontally scrolling category chips.
class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthSwitcher(),
        SizedBox(height: AppSpacing.md),
        _CategoryFilter(),
      ],
    );
  }
}

class _MonthSwitcher extends ConsumerWidget {
  const _MonthSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MonthRange month = ref.watch(
      historyControllerProvider.select((s) => s.filter.month),
    );
    final HistoryController controller = ref.read(
      historyControllerProvider.notifier,
    );
    final bool isCurrentMonth = month == MonthRange.of(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Bulan sebelumnya',
              iconSize: 24,
              onPressed: controller.previousMonth,
              icon: const Icon(FluentIcons.chevron_left_24_regular),
            ),
            Expanded(
              child: Text(
                DateFormatter.monthYear(month.start),
                textAlign: TextAlign.center,
                style: AppTypography.headingMedium,
              ),
            ),
            IconButton(
              tooltip: 'Bulan berikutnya',
              iconSize: 24,
              onPressed: isCurrentMonth ? null : controller.nextMonth,
              icon: const Icon(FluentIcons.chevron_right_24_regular),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> categories = ref.watch(
      historyControllerProvider.select((s) => s.categories),
    );
    final String? selected = ref.watch(
      historyControllerProvider.select((s) => s.filter.category),
    );
    final HistoryController controller = ref.read(
      historyControllerProvider.notifier,
    );

    return SizedBox(
      height: AppSpacing.minTouchTarget,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Semua',
            selected: selected == null,
            onTap: () => controller.setCategory(null),
          ),
          for (final String category in categories)
            _FilterChip(
              label: category,
              selected: selected == category,
              onTap: () => controller.setCategory(category),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: selected ? AppColors.onPrimary : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
