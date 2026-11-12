import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../data/savings_repository.dart';
import '../../domain/savings_bucket.dart';

class SavingsState extends Equatable {
  const SavingsState({
    required this.buckets,
    required this.freeBalance,
    required this.isLoading,
    this.errorMessage,
  });

  static const SavingsState initial = SavingsState(
    buckets: [],
    freeBalance: 0,
    isLoading: true,
  );

  final List<SavingsBucket> buckets;
  final double freeBalance;
  final bool isLoading;
  final String? errorMessage;

  double get totalAllocated =>
      buckets.fold(0, (sum, b) => sum + b.allocatedAmount);

  SavingsState copyWith({
    List<SavingsBucket>? buckets,
    double? freeBalance,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return SavingsState(
      buckets: buckets ?? this.buckets,
      freeBalance: freeBalance ?? this.freeBalance,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [buckets, freeBalance, isLoading, errorMessage];
}

final savingsControllerProvider =
    NotifierProvider.autoDispose<SavingsController, SavingsState>(
      SavingsController.new,
    );

class SavingsController extends AutoDisposeNotifier<SavingsState> {
  int _loadToken = 0;

  SavingsRepository get _repository => ref.read(savingsRepositoryProvider);

  @override
  SavingsState build() {
    ref.listen<int>(financeRevisionProvider, (_, _) => refresh());
    // Invalidates in-flight loads so they never write to a disposed notifier.
    ref.onDispose(() => _loadToken++);
    Future.microtask(refresh);
    return SavingsState.initial;
  }

  Future<void> refresh() async {
    final int token = ++_loadToken;
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final List<SavingsBucket> buckets = await _repository.getAll();
      final double free = await _repository.freeBalance();
      if (token != _loadToken) return;
      state = state.copyWith(
        buckets: buckets,
        freeBalance: free,
        isLoading: false,
      );
    } catch (error, stack) {
      debugPrint('Savings load failed: $error\n$stack');
      if (token != _loadToken) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Gagal memuat pos tabungan.',
      );
    }
  }

  Future<void> create({required String name, required double targetAmount}) =>
      _write(() => _repository.create(name: name, targetAmount: targetAmount));

  Future<void> allocate(int bucketId, double amount) =>
      _write(() => _repository.allocate(bucketId, amount));

  Future<void> withdraw(int bucketId, double amount) =>
      _write(() => _repository.withdraw(bucketId, amount));

  Future<void> delete(int bucketId) =>
      _write(() => _repository.delete(bucketId));

  // Errors propagate to the calling form; refresh happens via the revision.
  Future<void> _write(Future<Object?> Function() operation) async {
    await operation();
    ref.read(financeRevisionProvider.notifier).bump();
  }
}
