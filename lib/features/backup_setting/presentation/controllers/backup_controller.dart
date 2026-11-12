import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_providers.dart';
import '../../data/backup_local_data_source.dart';
import '../../data/google_drive_backup_service.dart';
import '../../domain/backup_models.dart';

enum BackupBusy { none, checking, signingIn, backingUp, restoring, signingOut }

class BackupMessage extends Equatable {
  const BackupMessage(this.text, {required this.isError});

  final String text;
  final bool isError;

  @override
  List<Object?> get props => [text, isError];
}

class BackupState extends Equatable {
  const BackupState({
    this.account,
    this.lastBackup,
    this.busy = BackupBusy.none,
    this.message,
  });

  final BackupAccount? account;
  final BackupInfo? lastBackup;
  final BackupBusy busy;
  final BackupMessage? message;

  bool get isSignedIn => account != null;
  bool get isBusy => busy != BackupBusy.none;

  BackupState copyWith({
    BackupAccount? Function()? account,
    BackupInfo? Function()? lastBackup,
    BackupBusy? busy,
    BackupMessage? Function()? message,
  }) {
    return BackupState(
      account: account != null ? account() : this.account,
      lastBackup: lastBackup != null ? lastBackup() : this.lastBackup,
      busy: busy ?? this.busy,
      message: message != null ? message() : this.message,
    );
  }

  @override
  List<Object?> get props => [account, lastBackup, busy, message];
}

// Lives for the whole app session: reopening the page reuses the account
// and last-backup info instead of re-checking Google every visit.
final backupControllerProvider =
    NotifierProvider<BackupController, BackupState>(BackupController.new);

// Asked on a first sign-in when the device profile already holds records.
typedef MoveDeviceDataPrompt = Future<bool> Function(String accountName);

class BackupController extends Notifier<BackupState> {
  GoogleDriveBackupService get _drive =>
      ref.read(googleDriveBackupServiceProvider);
  BackupLocalDataSource get _local => ref.read(backupLocalDataSourceProvider);
  ActiveAccount get _profiles => ref.read(activeAccountProvider.notifier);

  @override
  BackupState build() {
    Future.microtask(_restoreSession);
    return const BackupState(busy: BackupBusy.checking);
  }

  // Runs once per app launch, and only talks to Google when an account
  // profile is active; first-time users never see a sign-in prompt here.
  Future<void> _restoreSession() async {
    if (ref.read(activeAccountProvider) == null) {
      state = state.copyWith(busy: BackupBusy.none);
      return;
    }
    // An expired session keeps the profile: the data stays visible offline
    // and signing in again with the same account needs no prompt.
    final BackupAccount? account = await _drive.restoreSession();
    state = state.copyWith(account: () => account, busy: BackupBusy.none);
    if (account != null) await _loadLatest();
  }

  Future<void> _loadLatest() async {
    try {
      final BackupInfo? info = await _drive.latestBackup();
      state = state.copyWith(lastBackup: () => info);
    } on BackupException catch (e) {
      // Not fatal: the user can still back up.
      if (e.kind != BackupFailureKind.cancelled) {
        state = state.copyWith(
          message: () => BackupMessage(e.message, isError: true),
        );
      }
    }
  }

  // Signs in and switches to that account's data profile.
  Future<void> signIn({required MoveDeviceDataPrompt askMoveDeviceData}) =>
      _run(BackupBusy.signingIn, () async {
        final BackupAccount account = await _drive.signIn();
        final bool isNewProfile = !await _profiles.profileExists(account.email);
        final bool move =
            isNewProfile &&
            await _profiles.deviceHasData() &&
            await askMoveDeviceData(account.displayName ?? account.email);
        await _profiles.activate(
          account.email,
          displayName: account.displayName,
          moveDeviceData: move,
        );
        state = state.copyWith(account: () => account);
        await _loadLatest();
        if (isNewProfile && !move && state.lastBackup != null) {
          return 'Ada backup untuk akun ini di Google Drive. Tekan '
              '"Pulihkan dari Drive" untuk memuat datanya.';
        }
        return move ? 'Catatan di HP ini dipindahkan ke akun Anda.' : null;
      });

  // Returns to the device profile; the account's data stays on the phone.
  Future<void> signOut() => _run(BackupBusy.signingOut, () async {
    await _drive.signOut();
    await _profiles.deactivate();
    state = state.copyWith(account: () => null, lastBackup: () => null);
    return null;
  });

  Future<void> backup() => _run(BackupBusy.backingUp, () async {
    final BackupInfo info = await _drive.upload(await _local.exportBytes());
    state = state.copyWith(lastBackup: () => info);
    return 'Backup berhasil disimpan ke Google Drive.';
  });

  // Caller must confirm with the user first: local data is replaced.
  Future<void> restore() => _run(BackupBusy.restoring, () async {
    final List<int> bytes = await _drive.download();
    try {
      await _local.restoreBytes(bytes);
    } on DatabaseException catch (e) {
      throw BackupException(BackupFailureKind.invalidFile, '$e');
    }
    ref.read(financeRevisionProvider.notifier).bump();
    return 'Data berhasil dipulihkan dari Google Drive.';
  });

  void clearMessage() => state = state.copyWith(message: () => null);

  // Runs one action at a time; the task returns an optional success message.
  Future<void> _run(BackupBusy busy, Future<String?> Function() task) async {
    if (state.isBusy) return;
    state = state.copyWith(busy: busy, message: () => null);
    try {
      final String? success = await task();
      state = state.copyWith(
        busy: BackupBusy.none,
        message: () =>
            success == null ? null : BackupMessage(success, isError: false),
      );
    } on BackupException catch (e) {
      state = state.copyWith(
        busy: BackupBusy.none,
        message: () => e.kind == BackupFailureKind.cancelled
            ? null
            : BackupMessage(e.message, isError: true),
      );
    } catch (_) {
      state = state.copyWith(
        busy: BackupBusy.none,
        message: () => const BackupMessage(
          'Terjadi kesalahan. Silakan coba lagi.',
          isError: true,
        ),
      );
    }
  }
}
