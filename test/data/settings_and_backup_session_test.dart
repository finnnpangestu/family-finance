import 'dart:io';

import 'package:ff/core/database/app_database.dart';
import 'package:ff/core/database/database_providers.dart';
import 'package:ff/core/database/tables/categories_table.dart';
import 'package:ff/core/database/tables/expenses_table.dart';
import 'package:ff/core/database/tables/incomes_table.dart';
import 'package:ff/core/database/tables/savings_buckets_table.dart';
import 'package:ff/core/settings/app_currency.dart';
import 'package:ff/core/settings/settings_store.dart';
import 'package:ff/features/backup_setting/data/google_drive_backup_service.dart';
import 'package:ff/features/backup_setting/domain/backup_models.dart';
import 'package:ff/features/backup_setting/presentation/controllers/backup_controller.dart';
import 'package:ff/features/dashboard/data/finance_repository.dart';
import 'package:ff/features/dashboard/domain/models/income.dart';
import 'package:ff/features/dashboard/presentation/widgets/dashboard_top_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Stands in for Google; counts round-trips without the real plugin.
class _FakeDrive extends GoogleDriveBackupService {
  _FakeDrive({this.session, this.nextSignIn})
    : super(signIn: GoogleSignIn.instance);

  final BackupAccount? session;
  BackupAccount? nextSignIn;
  int restoreCalls = 0;

  @override
  Future<BackupAccount?> restoreSession() async {
    restoreCalls++;
    return session;
  }

  @override
  Future<BackupAccount> signIn() async => nextSignIn!;

  @override
  Future<void> signOut() async {}

  @override
  Future<BackupInfo?> latestBackup() async => null;
}

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late AppDatabase device;

  // Real files, so "profile exists" and reopening behave like on a phone.
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('ff_profiles');
    device = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: p.join(dir.path, AppDatabase.deviceFileName),
    );
  });

  tearDown(() async {
    await device.close();
    await dir.delete(recursive: true);
  });

  AppDatabase openProfile(String email) => AppDatabase(
    factory: databaseFactoryFfiNoIsolate,
    path: p.join(dir.path, profileFileName(email)),
  );

  ProviderContainer container({
    _FakeDrive? drive,
    AccountProfile? initialAccount,
  }) {
    final ProviderContainer c = ProviderContainer(
      overrides: [
        deviceDatabaseProvider.overrideWithValue(device),
        profileDatabaseOpenerProvider.overrideWithValue(openProfile),
        initialActiveAccountProvider.overrideWithValue(initialAccount),
        googleDriveBackupServiceProvider.overrideWithValue(
          drive ?? _FakeDrive(),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<List<String>> visibleIncomeSources(ProviderContainer c) =>
      c.read(financeRepositoryProvider).incomeCategories();

  Future<void> addIncome(ProviderContainer c, String source) => c
      .read(financeRepositoryProvider)
      .addIncome(
        Income(categoryName: source, amount: 1000, date: DateTime(2026, 5, 1)),
      );

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  group('AppDatabase migration', () {
    test('v1 database gains app_settings and keeps its data', () async {
      final String path = p.join(dir.path, 'v1.db');
      final Database v1 = await databaseFactoryFfiNoIsolate.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          // The complete first-release schema.
          onCreate: (db, _) async {
            await db.execute(IncomesTable.createSql);
            await db.execute(ExpensesTable.createSql);
            await db.execute(SavingsBucketsTable.createSql);
          },
        ),
      );
      await v1.insert(IncomesTable.name, {
        IncomesTable.categoryName: 'Gaji Utama',
        IncomesTable.amount: 1000,
        IncomesTable.date: '2026-01-01',
      });
      await v1.close();

      final AppDatabase upgraded = AppDatabase(
        factory: databaseFactoryFfiNoIsolate,
        path: path,
      );
      final SettingsStore store = SettingsStore(upgraded);
      await store.write(SettingsStore.currencyCode, 'USD');

      expect(await store.read(SettingsStore.currencyCode), 'USD');
      final Database migrated = await upgraded.database;
      expect(await migrated.query(IncomesTable.name), hasLength(1));
      // v3: transactions gained member_id, and used categories became
      // editable entries next to the defaults.
      expect(
        (await migrated.query(IncomesTable.name)).single,
        containsPair(IncomesTable.memberId, null),
      );
      final List<String> incomeCategories = [
        for (final row in await migrated.query(
          CategoriesTable.name,
          where: '${CategoriesTable.type} = ?',
          whereArgs: [CategoriesTable.typeIncome],
        ))
          row[CategoriesTable.categoryName] as String,
      ];
      expect(incomeCategories, contains('Gaji Utama'));
      expect(incomeCategories.toSet(), hasLength(incomeCategories.length));
      await upgraded.close();
    });
  });

  group('SettingsStore', () {
    test('overwrites and removes values', () async {
      final SettingsStore store = SettingsStore(device);
      expect(await store.read(SettingsStore.currencyCode), isNull);

      await store.write(SettingsStore.currencyCode, 'EUR');
      await store.write(SettingsStore.currencyCode, 'SGD');
      expect(await store.read(SettingsStore.currencyCode), 'SGD');

      await store.remove(SettingsStore.currencyCode);
      expect(await store.read(SettingsStore.currencyCode), isNull);
    });

    test('unknown currency codes fall back to Rupiah', () {
      expect(AppCurrency.fromCode('XYZ'), AppCurrency.idr);
      expect(AppCurrency.fromCode(null), AppCurrency.idr);
      expect(AppCurrency.fromCode('USD').symbol, r'$');
    });
  });

  group('Account profiles', () {
    test('file names hide the email and ignore case/spaces', () {
      final String name = profileFileName('Budi@Gmail.com ');
      expect(name, profileFileName('budi@gmail.com'));
      expect(name, isNot(contains('budi')));
      expect(name, isNot(profileFileName('ani@gmail.com')));
    });

    test('each account sees only its own records', () async {
      final ProviderContainer c = container();
      final ActiveAccount profiles = c.read(activeAccountProvider.notifier);

      await addIncome(c, 'Catatan HP');
      await profiles.activate('ani@gmail.com');
      expect(await visibleIncomeSources(c), isEmpty);
      await addIncome(c, 'Gaji Ani');

      await profiles.activate('budi@gmail.com');
      expect(await visibleIncomeSources(c), isEmpty);
      await addIncome(c, 'Gaji Budi');

      await profiles.activate('ani@gmail.com');
      expect(await visibleIncomeSources(c), ['Gaji Ani']);

      await profiles.deactivate();
      expect(await visibleIncomeSources(c), ['Catatan HP']);
    });

    test('moving device data empties the device profile', () async {
      final ProviderContainer c = container();
      final ActiveAccount profiles = c.read(activeAccountProvider.notifier);
      await addIncome(c, 'Catatan HP');
      expect(await profiles.deviceHasData(), isTrue);

      await profiles.activate('ani@gmail.com', moveDeviceData: true);

      expect(await visibleIncomeSources(c), ['Catatan HP']);
      expect(await profiles.deviceHasData(), isFalse);
      expect(await profiles.profileExists('ani@gmail.com'), isTrue);
      expect(await profiles.profileExists('budi@gmail.com'), isFalse);
    });

    test('active account and name persist in device settings', () async {
      final ProviderContainer c = container();
      await c
          .read(activeAccountProvider.notifier)
          .activate('Ani@Gmail.com', displayName: 'Ani Lestari');

      final SettingsStore store = SettingsStore(device);
      expect(await store.read(SettingsStore.activeAccount), 'ani@gmail.com');
      expect(await store.read(SettingsStore.activeAccountName), 'Ani Lestari');
      expect(c.read(activeAccountProvider)?.firstName, 'Ani');
    });

    test('greeting adds the first name only when known', () {
      final DateTime morning = DateTime(2026, 1, 1, 8);
      expect(
        DashboardTopBar.personalGreeting(morning, 'Ani'),
        'Selamat pagi, Ani',
      );
      expect(DashboardTopBar.personalGreeting(morning, null), 'Selamat pagi');
      expect(
        const AccountProfile(email: 'a@b.c', displayName: '  ').firstName,
        isNull,
      );
    });
  });

  group('BackupController session', () {
    test('never contacts Google without an active account', () async {
      final _FakeDrive drive = _FakeDrive();
      final ProviderContainer c = container(drive: drive);
      c.read(backupControllerProvider);
      await settle();

      expect(drive.restoreCalls, 0);
      expect(c.read(backupControllerProvider).busy, BackupBusy.none);
    });

    test('restores once and reuses the session on later visits', () async {
      final _FakeDrive drive = _FakeDrive(
        session: const BackupAccount(email: 'ani@gmail.com'),
      );
      final ProviderContainer c = container(
        drive: drive,
        initialAccount: const AccountProfile(email: 'ani@gmail.com'),
      );
      c.read(backupControllerProvider);
      await settle();
      expect(drive.restoreCalls, 1);
      expect(c.read(backupControllerProvider).isSignedIn, isTrue);

      // Revisiting the page reads the same live controller.
      c.read(backupControllerProvider);
      await settle();
      expect(drive.restoreCalls, 1);
    });

    test('expired session keeps showing the account data', () async {
      final ProviderContainer c = container(
        drive: _FakeDrive(),
        initialAccount: const AccountProfile(email: 'ani@gmail.com'),
      );
      c.read(backupControllerProvider);
      await settle();

      expect(c.read(backupControllerProvider).isSignedIn, isFalse);
      expect(c.read(activeAccountProvider)?.email, 'ani@gmail.com');
    });

    test('first sign-in asks before moving device records', () async {
      final _FakeDrive drive = _FakeDrive(
        nextSignIn: const BackupAccount(
          email: 'ani@gmail.com',
          displayName: 'Ani',
        ),
      );
      final ProviderContainer c = container(drive: drive);
      await addIncome(c, 'Catatan HP');
      c.read(backupControllerProvider);
      await settle();

      final List<String> asked = [];
      await c
          .read(backupControllerProvider.notifier)
          .signIn(
            askMoveDeviceData: (name) async {
              asked.add(name);
              return true;
            },
          );

      expect(asked, ['Ani']);
      expect(await visibleIncomeSources(c), ['Catatan HP']);

      // Signing out returns to the (now empty) device profile.
      await c.read(backupControllerProvider.notifier).signOut();
      expect(c.read(activeAccountProvider), isNull);
      expect(await visibleIncomeSources(c), isEmpty);

      // The same account again: no question, its data is back.
      await c
          .read(backupControllerProvider.notifier)
          .signIn(askMoveDeviceData: (_) async => fail('must not ask again'));
      expect(await visibleIncomeSources(c), ['Catatan HP']);
    });
  });
}
