import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../data/finance_repository.dart';
import '../../domain/models/dashboard_summary.dart';
import '../../domain/models/month_range.dart';
import 'dashboard_state.dart';

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );

class DashboardController extends Notifier<DashboardState> {
  // Drops results of superseded loads when writes happen quickly.
  int _loadToken = 0;

  @override
  DashboardState build() {
    ref.listen<int>(financeRevisionProvider, (_, _) => refresh());
    Future.microtask(refresh);
    return DashboardState.initial;
  }

  Future<void> refresh() async {
    final int token = ++_loadToken;
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final DashboardSummary summary = await ref
          .read(financeRepositoryProvider)
          .loadSummary(MonthRange.of(DateTime.now()));
      if (token != _loadToken) return;
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (error, stack) {
      debugPrint('Dashboard load failed: $error\n$stack');
      if (token != _loadToken) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Gagal memuat ringkasan keuangan.',
      );
    }
  }
}
