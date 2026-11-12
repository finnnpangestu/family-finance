# STATE_MANAGEMENT.md - Riverpod Implementation Guide

## 1. Core Principles

- Immutable State: State objects are immutable. Use freezed or copyWith to emit new state instances.
- Localized Listening: Rebuild only the specific UI subtree that consumes updated data.
- Zero Page Rebuilds: Main page (xxx_page.dart) should not rebuild entirely when new transactions are added.

## 2. Provider Structure Pattern

```dart
final dashboardControllerProvider = StateNotifierProvider<DashboardController, DashboardState>((ref) {
  return DashboardController(ref.watch(dashboardRepositoryProvider));
});
```

## 3. UI Consumption Rule

Wrap target widgets with Consumer or ConsumerWidget:

```dart
Consumer(
  builder: (context, ref, child) {
    final totalIncome = ref.watch(dashboardControllerProvider.select((s) => s.totalIncome));
    return Text(CurrencyFormatter.formatRupiah(totalIncome));
  },
);
```
