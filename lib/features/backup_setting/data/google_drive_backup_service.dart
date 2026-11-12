import 'dart:async';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../domain/backup_models.dart';

final googleDriveBackupServiceProvider = Provider<GoogleDriveBackupService>(
  (ref) => GoogleDriveBackupService(),
);

// Stores a single backup file in the user's hidden Drive appDataFolder.
class GoogleDriveBackupService {
  GoogleDriveBackupService({GoogleSignIn? signIn})
    : _signIn = signIn ?? GoogleSignIn.instance;

  static const String fileName = 'ff_backup.json';
  static const String _folder = 'appDataFolder';
  static const List<String> scopes = [drive.DriveApi.driveAppdataScope];

  // Web OAuth client id, required by Android Credential Manager.
  // Set GOOGLE_SERVER_CLIENT_ID in .env file.
  static String get _serverClientId =>
      dotenv.maybeGet('GOOGLE_SERVER_CLIENT_ID') ?? '';

  final GoogleSignIn _signIn;
  Future<void>? _initializing;
  GoogleSignInAccount? _account;

  Future<void> _ensureInitialized() => _initializing ??= _signIn
      .initialize(
        serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
      )
      .catchError((Object error) {
        // Allow a retry after a failed initialization.
        _initializing = null;
        throw _mapError(error);
      });

  // Silent sign-in; returns null when no session exists. An account already
  // held in memory is reused so Google is not asked again.
  Future<BackupAccount?> restoreSession() async {
    final GoogleSignInAccount? cached = _account;
    if (cached != null) return _toAccount(cached);
    try {
      await _ensureInitialized();
      final GoogleSignInAccount? account = await _signIn
          .attemptLightweightAuthentication();
      _account = account;
      return account == null ? null : _toAccount(account);
    } catch (error) {
      debugPrint('Silent sign-in skipped: $error');
      return null;
    }
  }

  Future<BackupAccount> signIn() => _guard(() async {
    await _ensureInitialized();
    if (!_signIn.supportsAuthenticate()) {
      throw const BackupException(BackupFailureKind.unsupported);
    }
    final GoogleSignInAccount account = await _signIn.authenticate(
      scopeHint: scopes,
    );
    _account = account;
    return _toAccount(account);
  });

  Future<void> signOut() => _guard(() async {
    await _ensureInitialized();
    await _signIn.signOut();
    _account = null;
  });

  // Runs silently; returns null when Drive access was never granted.
  Future<BackupInfo?> latestBackup() =>
      _withDrive(interactive: false, (api) async {
        final drive.File? file = await _findBackup(api);
        if (file == null) return null;
        return BackupInfo(
          modifiedTime: file.modifiedTime?.toLocal(),
          sizeBytes: int.tryParse(file.size ?? ''),
        );
      });

  Future<BackupInfo> upload(List<int> bytes) => _withDrive((api) async {
    final drive.Media media = drive.Media(
      Stream<List<int>>.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );
    final drive.File? existing = await _findBackup(api);
    final String? existingId = existing?.id;
    final drive.File saved = existingId != null
        ? await api.files.update(
            drive.File(),
            existingId,
            uploadMedia: media,
            $fields: 'id,modifiedTime,size',
          )
        : await api.files.create(
            drive.File(name: fileName, parents: [_folder]),
            uploadMedia: media,
            $fields: 'id,modifiedTime,size',
          );
    return BackupInfo(
      modifiedTime: saved.modifiedTime?.toLocal() ?? DateTime.now(),
      sizeBytes: int.tryParse(saved.size ?? '') ?? bytes.length,
    );
  });

  Future<List<int>> download() => _withDrive((api) async {
    final drive.File? file = await _findBackup(api);
    final String? id = file?.id;
    if (id == null) throw const BackupException(BackupFailureKind.notFound);
    final Object response = await api.files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );
    if (response is! drive.Media) {
      throw const BackupException(BackupFailureKind.invalidFile, 'no media');
    }
    final List<int> bytes = [];
    await for (final List<int> chunk in response.stream) {
      bytes.addAll(chunk);
    }
    return bytes;
  });

  Future<drive.File?> _findBackup(drive.DriveApi api) async {
    final drive.FileList list = await api.files.list(
      spaces: _folder,
      q: "name = '$fileName' and trashed = false",
      orderBy: 'modifiedTime desc',
      pageSize: 1,
      $fields: 'files(id,name,modifiedTime,size)',
    );
    final List<drive.File> files = list.files ?? const [];
    return files.isEmpty ? null : files.first;
  }

  // Authorizes Drive scope and always closes the client. Prompts the user
  // only when [interactive]; otherwise a missing grant yields null.
  Future<T?> _withDriveOrNull<T>(
    Future<T> Function(drive.DriveApi api) action, {
    required bool interactive,
  }) => _guard(() async {
    await _ensureInitialized();
    GoogleSignInAccount? account = _account;
    if (account == null) {
      if (!interactive) return null;
      account = await _signIn.authenticate(scopeHint: scopes);
    }
    _account = account;

    final GoogleSignInAuthorizationClient authz = account.authorizationClient;
    GoogleSignInClientAuthorization? authorization = await authz
        .authorizationForScopes(scopes);
    if (authorization == null) {
      if (!interactive) return null;
      authorization = await authz.authorizeScopes(scopes);
    }

    final http.Client client = authorization.authClient(scopes: scopes);
    try {
      return await action(drive.DriveApi(client));
    } finally {
      client.close();
    }
  });

  Future<T> _withDrive<T>(
    Future<T> Function(drive.DriveApi api) action, {
    bool interactive = true,
  }) async {
    // Interactive calls authorize or throw, so null only comes from [action].
    final T? result = await _withDriveOrNull(action, interactive: interactive);
    return result as T;
  }

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stack) {
      debugPrint('Drive backup error: $error\n$stack');
      throw _mapError(error);
    }
  }

  static BackupException _mapError(Object error) {
    if (error is BackupException) return error;
    if (error is GoogleSignInException) {
      // Credential Manager reports OAuth misconfiguration as "[16] Account
      // reauth failed", "[28444] Developer console is not set up correctly"
      // or, for a client Google has not propagated yet, "[28404] Failed to
      // retrieve an ID token".
      final String description = error.description ?? '';
      if (const ['[16]', '[28444]', '[28404]'].any(description.contains)) {
        return BackupException(
          BackupFailureKind.notConfigured,
          error.description,
        );
      }
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted => BackupException(
          BackupFailureKind.cancelled,
          error.description,
        ),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError => BackupException(
          BackupFailureKind.notConfigured,
          error.description,
        ),
        GoogleSignInExceptionCode.uiUnavailable => BackupException(
          BackupFailureKind.unsupported,
          error.description,
        ),
        _ => BackupException(BackupFailureKind.unknown, error.description),
      };
    }
    if (error is SocketException ||
        error is http.ClientException ||
        error is TimeoutException) {
      return BackupException(BackupFailureKind.network, '$error');
    }
    if (error is drive.DetailedApiRequestError && error.status == 404) {
      return BackupException(BackupFailureKind.notFound, error.message);
    }
    return BackupException(BackupFailureKind.unknown, '$error');
  }

  static BackupAccount _toAccount(GoogleSignInAccount account) =>
      BackupAccount(email: account.email, displayName: account.displayName);
}
