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

final backupControllerProvider =
    NotifierProvider.autoDispose<BackupController, BackupState>(
      BackupController.new,
    );

class BackupController extends AutoDisposeNotifier<BackupState> {
  GoogleDriveBackupService get _drive =>
      ref.read(googleDriveBackupServiceProvider);
  BackupLocalDataSource get _local => ref.read(backupLocalDataSourceProvider);

  @override
  BackupState build() {
    Future.microtask(_restoreSession);
    return const BackupState(busy: BackupBusy.checking);
  }

  Future<void> _restoreSession() async {
    final KeepAliveLink keepAlive = ref.keepAlive();
    try {
      final BackupAccount? account = await _drive.restoreSession();
      state = state.copyWith(account: () => account, busy: BackupBusy.none);
      if (account != null) await _loadLatest();
    } finally {
      keepAlive.close();
    }
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

  Future<void> signIn() => _run(BackupBusy.signingIn, () async {
    final BackupAccount account = await _drive.signIn();
    state = state.copyWith(account: () => account);
    await _loadLatest();
    return null;
  });

  Future<void> signOut() => _run(BackupBusy.signingOut, () async {
    await _drive.signOut();
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
    // A restore must finish even if the user leaves the page.
    final KeepAliveLink keepAlive = ref.keepAlive();
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
    } finally {
      keepAlive.close();
    }
  }
}
