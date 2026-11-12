# FF — Family Finance

Aplikasi pencatatan keuangan keluarga yang **100% offline-first**, ramah lansia, dan tanpa biaya server. Dibangun dengan Flutter, SQLite (sqflite), dan Riverpod.

## Fitur V1

- **Dashboard tunggal** (tanpa bottom navbar): total pemasukan bulan ini per sumber, kartu Masuk / Keluar / Sisa Saldo Bebas, menu aksi cepat.
- **Pemasukan multi-sumber**: Gaji Utama, Usaha Sampingan, atau sumber baru yang diketik sendiri.
- **Pengeluaran dua mode**: Catat Cepat (total harian) dan Catat Rinci (per item, disimpan atomik).
- **Pos Tabungan**: alokasi dana dari saldo bebas, target & progres, ambil dana kembali.
- **Riwayat adaptif**: filter bulan & kategori; tablet memakai split view dengan detail + grafik pengeluaran.
- **Backup Google Drive** (opsional) ke `appDataFolder` pribadi pengguna.

Voice-to-text (PRD F-06) ditunda karena opsional di V1.

## Menjalankan

```bash
flutter pub get
flutter run
flutter test
```

Font Plus Jakarta Sans sudah dibundel di `assets/google_fonts/` (lisensi OFL), jadi aplikasi tidak butuh internet untuk tampil benar.

## Setup Backup Google Drive

Fitur lain berjalan tanpa setup ini. Untuk mengaktifkan backup:

1. Buat project di [Google Cloud Console](https://console.cloud.google.com/), aktifkan **Google Drive API**.
2. Konfigurasi **OAuth consent screen**, tambahkan scope `https://www.googleapis.com/auth/drive.appdata`.
3. Buat OAuth Client ID:
   - **Android**: package `com.familyfinance.ff` + SHA-1 keystore (`cd android && ./gradlew signingReport`).
   - **Web application**: client ID ini dipakai sebagai `serverClientId` (dibutuhkan Credential Manager di Android).
   - **iOS** (opsional): bundle id dari `ios/Runner.xcodeproj`, lalu ikuti README `google_sign_in_ios` untuk `GIDClientID` dan URL scheme di `Info.plist`.
4. Jalankan dengan client ID web:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
```

## Struktur

Feature-first semi-clean architecture (lihat `ARCHITECTURE.md`, `PROJECT_STRUCTURE.md`):

```
lib/
├── core/        # database, theme tokens, utils, widget global (AppBottomSheet, AppButton, ...)
└── features/
    ├── dashboard/            # ringkasan + form transaksi
    ├── transaction_history/  # riwayat mobile/tablet
    ├── savings_bucket/       # pos tabungan
    └── backup_setting/       # Google Drive backup
```

Setiap halaman: `xxx_page.dart` (LayoutBuilder router) → `xxx_mobile.dart` (< 600dp) / `xxx_tablet.dart` (≥ 600dp).

## Dokumentasi

| File                                           | Isi                                               |
| ---------------------------------------------- | ------------------------------------------------- |
| `PRD.md`                                       | Kebutuhan produk & skema database                 |
| `DESIGN_SYSTEM.md`                             | Warna, tipografi, ikon, bottom sheet, breakpoint  |
| `ARCHITECTURE.md`, `PROJECT_STRUCTURE.md`      | Layer & tata letak folder                         |
| `STATE_MANAGEMENT.md`                          | Aturan Riverpod                                   |
| `CODING_STANDARD.md`, `AGENTS.md`, `CLAUDE.md` | Aturan coding & AI agent                          |
| `SPECS.md`                                     | Rencana implementasi V1, aturan bisnis, edge case |
| `docs/`                                        | File asli (format Word) dari dokumen di atas      |
