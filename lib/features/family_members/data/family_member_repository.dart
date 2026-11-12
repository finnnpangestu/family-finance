import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/tables/expenses_table.dart';
import '../../../core/database/tables/family_members_table.dart';
import '../../../core/database/tables/incomes_table.dart';
import '../../../core/database/tables/recurring_transactions_table.dart';
import '../domain/family_member.dart';

final familyMemberRepositoryProvider = Provider<FamilyMemberRepository>(
  (ref) => FamilyMemberRepository(ref.watch(appDatabaseProvider)),
);

final familyMembersProvider = FutureProvider.autoDispose<List<FamilyMember>>((
  ref,
) {
  ref.watch(financeRevisionProvider);
  return ref.watch(familyMemberRepositoryProvider).list();
});

// Thrown when a name is already taken, so the form can say so.
class DuplicateMemberException implements Exception {
  const DuplicateMemberException(this.name);

  final String name;
}

class FamilyMemberRepository {
  const FamilyMemberRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<FamilyMember>> list() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      FamilyMembersTable.name,
      orderBy: FamilyMembersTable.id,
    );
    return [
      for (final row in rows)
        FamilyMember(
          id: row[FamilyMembersTable.id] as int,
          name: row[FamilyMembersTable.memberName] as String,
        ),
    ];
  }

  Future<int> add(String name) async {
    final Database db = await _appDatabase.database;
    try {
      return await db.insert(FamilyMembersTable.name, {
        FamilyMembersTable.memberName: name.trim(),
      });
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw DuplicateMemberException(name);
      rethrow;
    }
  }

  // Transactions survive as "unassigned" rather than being deleted.
  Future<void> remove(int id) async {
    final Database db = await _appDatabase.database;
    await db.transaction((txn) async {
      for (final (String table, String column) in const [
        (IncomesTable.name, IncomesTable.memberId),
        (ExpensesTable.name, ExpensesTable.memberId),
        (RecurringTransactionsTable.name, RecurringTransactionsTable.memberId),
      ]) {
        await txn.update(
          table,
          {column: null},
          where: '$column = ?',
          whereArgs: [id],
        );
      }
      await txn.delete(
        FamilyMembersTable.name,
        where: '${FamilyMembersTable.id} = ?',
        whereArgs: [id],
      );
    });
  }
}
