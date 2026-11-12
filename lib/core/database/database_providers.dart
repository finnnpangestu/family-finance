import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// Bumped after every write so dependent features refresh without
// coupling to each other.
final financeRevisionProvider = NotifierProvider<FinanceRevision, int>(
  FinanceRevision.new,
);

class FinanceRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
