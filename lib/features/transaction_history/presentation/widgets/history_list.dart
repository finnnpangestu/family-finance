import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/transaction_entry.dart';
import '../controllers/history_controller.dart';
import 'transaction_tile.dart';

class HistoryList extends ConsumerWidget {
  const HistoryList({
    super.key,
    required this.onEntryTap,
    this.highlightSelection = false,
  });

  final ValueChanged<TransactionEntry> onEntryTap;

  // Tablet split view marks the entry shown in the detail pane.
  final bool highlightSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<TransactionEntry> entries = ref.watch(
      historyControllerProvider.select((s) => s.entries),
    );
    final bool isLoading = ref.watch(
      historyControllerProvider.select((s) => s.isLoading),
    );
    final String? error = ref.watch(
      historyControllerProvider.select((s) => s.errorMessage),
    );

    if (error != null) {
      return ErrorView(
        message: error,
        onRetry: () => ref.read(historyControllerProvider.notifier).refresh(),
      );
    }
    if (entries.isEmpty) {
      return isLoading
          ? const LoadingView()
          : const EmptyView(
              icon: FluentIcons.receipt_48_regular,
              message: 'Belum ada transaksi di bulan ini.',
            );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final TransactionEntry entry = entries[index];
        return highlightSelection
            ? _SelectableTile(entry: entry, onTap: () => onEntryTap(entry))
            : TransactionTile(entry: entry, onTap: () => onEntryTap(entry));
      },
    );
  }
}

// Only the tiles whose selection flag flips rebuild.
class _SelectableTile extends ConsumerWidget {
  const _SelectableTile({required this.entry, required this.onTap});

  final TransactionEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool selected = ref.watch(
      historyControllerProvider.select((s) => s.selectedKey == entry.key),
    );
    return TransactionTile(entry: entry, onTap: onTap, selected: selected);
  }
}
