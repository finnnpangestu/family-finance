import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../settings/settings_store.dart';
import 'app_database.dart';
import 'tables/categories_table.dart';

// Fixed database: data recorded without an account + device-wide settings.
final deviceDatabaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

typedef ProfileDatabaseOpener = AppDatabase Function(String email);

// One database file per Google account; tests swap in temp-file databases.
final profileDatabaseOpenerProvider = Provider<ProfileDatabaseOpener>(
  (_) =>
      (email) => AppDatabase(fileName: profileFileName(email)),
);

// The email is hashed so it never appears in a file name.
String profileFileName(String email) {
  // FNV-1a 64-bit: stable across runs, no extra dependency.
  BigInt hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final BigInt prime = BigInt.parse('100000001b3', radix: 16);
  final BigInt mask = (BigInt.one << 64) - BigInt.one;
  for (final int unit in email.trim().toLowerCase().codeUnits) {
    hash = ((hash ^ BigInt.from(unit)) * prime) & mask;
  }
  return 'ff_acct_${hash.toRadixString(16).padLeft(16, '0')}.db';
}

// Signed-in Google account that owns the visible data.
class AccountProfile extends Equatable {
  const AccountProfile({required this.email, this.displayName});

  final String email;
  final String? displayName;

  // "Muhammad Rizki" -> "Muhammad"; null when Google gave no name.
  String? get firstName {
    final String? name = displayName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  List<Object?> get props => [email, displayName];
}

// Read in main() before the first frame so the right data shows instantly.
final initialActiveAccountProvider = Provider<AccountProfile?>((_) => null);

// Database of the active profile. Every repository watches this, so a
// profile switch moves the whole app to the other file.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  // Only the email picks the file; a name change must not reopen it.
  final String? account = ref.watch(
    activeAccountProvider.select((a) => a?.email),
  );
  if (account == null) return ref.watch(deviceDatabaseProvider);
  final AppDatabase db = ref.watch(profileDatabaseOpenerProvider)(account);
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

// Account whose data is shown; null = device profile.
final activeAccountProvider = NotifierProvider<ActiveAccount, AccountProfile?>(
  ActiveAccount.new,
);

class ActiveAccount extends Notifier<AccountProfile?> {
  @override
  AccountProfile? build() => ref.read(initialActiveAccountProvider);

  SettingsStore get _settings => ref.read(settingsStoreProvider);

  Future<bool> profileExists(String email) =>
      ref.read(profileDatabaseOpenerProvider)(email).exists();

  Future<bool> deviceHasData() async {
    final db = await ref.read(deviceDatabaseProvider).database;
    for (final String table in AppDatabase.tableNames) {
      // Categories are always seeded, so they never count as user data.
      if (table == CategoriesTable.name) continue;
      final rows = await db.rawQuery('SELECT 1 FROM $table LIMIT 1');
      if (rows.isNotEmpty) return true;
    }
    return false;
  }

  // Switches to [email]'s data. With [moveDeviceData] the device profile's
  // records are moved into the account first; on failure nothing switches.
  Future<void> activate(
    String email, {
    String? displayName,
    bool moveDeviceData = false,
  }) async {
    final String normalized = email.trim().toLowerCase();
    if (moveDeviceData) await _moveDeviceDataTo(normalized);
    await _settings.write(SettingsStore.activeAccount, normalized);
    final String? name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      await _settings.write(SettingsStore.activeAccountName, name);
    } else {
      await _settings.remove(SettingsStore.activeAccountName);
    }
    _switchTo(AccountProfile(email: normalized, displayName: name));
  }

  // Back to the device profile; the account's file stays for next sign-in.
  Future<void> deactivate() async {
    await _settings.remove(SettingsStore.activeAccount);
    await _settings.remove(SettingsStore.activeAccountName);
    _switchTo(null);
  }

  void _switchTo(AccountProfile? account) {
    final bool dataChanges = state?.email != account?.email;
    state = account;
    if (dataChanges) ref.read(financeRevisionProvider.notifier).bump();
  }

  Future<void> _moveDeviceDataTo(String email) async {
    final device = await ref.read(deviceDatabaseProvider).database;
    final AppDatabase profile = ref.read(profileDatabaseOpenerProvider)(email);
    try {
      final target = await profile.database;
      // The target is a brand-new profile, so ids are kept (transactions
      // keep pointing at their members). Replace only resolves the default
      // categories the new file was seeded with.
      await target.transaction((txn) async {
        for (final String table in AppDatabase.tableNames) {
          final rows = await device.query(
            table,
            columns: AppDatabase.profileColumns[table],
          );
          final batch = txn.batch();
          for (final row in rows) {
            batch.insert(
              table,
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        }
      });
    } finally {
      // appDatabaseProvider opens its own connection after the switch.
      await profile.close();
    }
    // Only cleared after the copy committed, so a failure loses nothing.
    // Default categories return so the device profile stays usable.
    await device.transaction((txn) async {
      for (final String table in AppDatabase.tableNames.reversed) {
        await txn.delete(table);
      }
      await AppDatabase.seedDefaultCategories(txn);
    });
  }
}
