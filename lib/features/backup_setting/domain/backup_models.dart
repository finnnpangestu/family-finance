import 'package:equatable/equatable.dart';

class BackupInfo extends Equatable {
  const BackupInfo({required this.modifiedTime, required this.sizeBytes});

  final DateTime? modifiedTime;
  final int? sizeBytes;

  @override
  List<Object?> get props => [modifiedTime, sizeBytes];
}

class BackupAccount extends Equatable {
  const BackupAccount({required this.email, this.displayName});

  final String email;
  final String? displayName;

  @override
  List<Object?> get props => [email, displayName];
}

enum BackupFailureKind {
  cancelled,
  notConfigured,
  unsupported,
  network,
  notFound,
  invalidFile,
  unknown,
}

// Typed failure so the UI can show a friendly, specific message.
class BackupException implements Exception {
  const BackupException(this.kind, [this.detail]);

  final BackupFailureKind kind;
  final String? detail;

  String get message => switch (kind) {
    BackupFailureKind.cancelled => 'Proses dibatalkan.',
    BackupFailureKind.notConfigured =>
      'Login ditolak Google. Pastikan aplikasi Android (package & SHA-1) '
          'sudah terdaftar di Google Cloud dan akun ini termasuk Test user.',
    BackupFailureKind.unsupported =>
      'Perangkat ini tidak mendukung login Google.',
    BackupFailureKind.network =>
      'Tidak dapat terhubung. Periksa koneksi internet Anda.',
    BackupFailureKind.notFound => 'Belum ada backup di Google Drive.',
    BackupFailureKind.invalidFile =>
      'File backup rusak atau dari versi aplikasi yang lebih baru.',
    BackupFailureKind.unknown => 'Terjadi kesalahan. Silakan coba lagi.',
  };

  @override
  String toString() => 'BackupException($kind, $detail)';
}
