# PRD.md - Family Finance Tracker (Offline-First)

## 1. Executive Summary & Vision

Aplikasi pencatatan keuangan keluarga yang ringan, 100% offline-first, gratis biaya server, dan sangat ramah orang tua/lansia. Aplikasi dirancang untuk berjalan mulus di perangkat dengan spesifikasi rendah (RAM 2GB, Android jadul hingga versi Android/iOS terbaru).

## 2. Core Constraints & Technical Principles

- Zero Monthly Infrastructure Cost: Tanpa backend cloud berbayar.
- Offline-First Storage: Menggunakan SQLite (sqflite) yang sangat ringan (< 5MB footprint RAM).
- Google Drive Cloud Backup: Fitur backup/restore opsional ke akun Google Drive pribadi pengguna (appDataFolder).
- Senior UX Priority: Elemen visual berukuran besar, warna kontras tinggi, navigasi tunggal tanpa Bottom Navbar yang membingungkan.
- Fixed Typography: Standardisasi ukuran font dengan textScaler: 1.0.

## 3. Architecture & Folder Structure (Semi-Clean Architecture)

Menggunakan pola Semi-Clean Architecture modular berbasis fitur (Feature-First) untuk memudahkan pemeliharaan kode dan konsistensi pemisahan layout Mobile vs Tablet:

```
lib/
├── core/
│   ├── database/          # SQLite helper & migration scripts
│   ├── theme/             # Design Tokens (AppColors, AppTypography, AppTheme)
│   ├── utils/             # Formatters (Currency, Date), Global Dialogs
│   └── widgets/           # Global Reusable Components (AppButton, AppBottomSheet)
│
├── features/
│   ├── dashboard/
│   │   ├── data/          # Dashboard Repository & Database Queries
│   │   ├── domain/        # Dashboard Models (Summary, IncomeTotal, ExpenseTotal)
│   │   └── presentation/  # UI & Logic State
│   │       ├── controllers/ # State Management Controller / Notifier
│   │       ├── widgets/    # Micro Components (IncomeCard, SummaryHeader)
│   │       └── page/
│   │           ├── dashboard_page.dart    # Main Entry Point (Controller Init & Responsive Router)
│   │           ├── dashboard_mobile.dart  # Mobile Layout (< 600dp)
│   │           └── dashboard_tablet.dart  # Tablet Layout (>= 600dp)
│   │
│   ├── transaction_history/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── widgets/
│   │       └── page/
│   │           ├── history_page.dart
│   │           ├── history_mobile.dart
│   │           └── history_tablet.dart
│   │
│   └── backup_setting/
│       ├── data/
│       └── presentation/
│
└── main.dart
```

## 4. Feature Specifications

### F-01: Central Dashboard (Single Hub)

- Deskripsi: Pusat kontrol utama aplikasi tanpa Bottom Navbar. Seluruh fitur diakses dari dashboard ini.
- Elemen:
  - Header Total Income: Menampilkan penjumlahan dari Income Stream A + Income Stream B.
  - Ringkasan Pengeluaran & Sisa Saldo: Kartu indikator besar (Hijau = Masuk, Merah = Keluar, Biru = Sisa).
  - Quick Actions:
    - Tombol + Tambah Transaksi (Membuka Global Bottom Sheet Form).
    - Tombol Riwayat Transaksi (Navigasi ke HistoryPage).
    - Tombol Pos Tabungan (Navigasi ke SavingsBucketPage).
    - Tombol Backup Google Drive (Navigasi ke BackupPage).

### F-02: Multi-Stream Income Management

- Deskripsi: Mendukung pengelompokan sumber pemasukan (contoh: Gaji Utama, Usaha/Sampingan).
- Aturan Bisnis:
  - Pengguna bisa menambah kategori pemasukan sesuai kebutuhan.
  - Setiap nominal pemasukan otomatis terakumulasi ke Total Income.

### F-03: Dual-Mode Expense Recorder (via Slide-Up Bottom Sheet)

- Mode Catat Cepat (Lump-Sum):
  - Pengguna cukup memasukkan nominal total harian (contoh: Pengeluaran Hari Selasa: Rp 300.000).
- Mode Catat Rinci (Itemized):
  - Pengguna mencatat per item transaksi (contoh: Listrik: Rp 100.000, Air: Rp 100.000).
- Keyboard Logic: Form angka secara otomatis memicu TextInputType.number bawaan Android dengan Numpad bawaan HP.

### F-04: Pos Alokasi & Tabungan (Savings Buckets)

- Deskripsi: Membagi Total Income ke pos-pos tabungan atau pengeluaran khusus (contoh: Tabungan A, Tabungan B, Dana Darurat).
- Aturan Bisnis: Pemasukan yang dialokasikan ke Pos Tabungan akan mengurangi Sisa Saldo Bebas yang bisa dipakai untuk pengeluaran harian.

### F-05: Adaptive History & Transaction Details

- Mobile View (history_mobile.dart):
  - Tampilan List Item vertikal yang tinggi dan lapang (min height 72dp per item).
  - Filter sederhana berdasarkan Bulan & Kategori di bagian atas.
- Tablet View (history_tablet.dart):
  - Tampilan Dual-Pane (Split View): Sisi kiri daftar riwayat transaksi, sisi kanan detail transaksi lengkap beserta grafik pengeluaran sederhana.

### F-06: 100% Offline Voice-to-Text Transaction (Opsional V1)

- Deskripsi: Memanfaatkan library speech_to_text yang terhubung ke Google Voice Engine bawaan Android.
- Regex Parser: Mengonversi kalimat lisan secara lokal menjadi Nominal & Kategori tanpa memanggil API AI berbayar.

## 5. Database Schema (SQLite sqflite)

### Table: incomes

- id INTEGER PRIMARY KEY AUTOINCREMENT
- category_name TEXT NOT NULL
- amount REAL NOT NULL
- date TEXT NOT NULL
- note TEXT

### Table: expenses

- id INTEGER PRIMARY KEY AUTOINCREMENT
- is_lumpsum INTEGER NOT NULL
- category_name TEXT NOT NULL
- item_name TEXT
- amount REAL NOT NULL
- date TEXT NOT NULL
- note TEXT

### Table: savings_buckets

- id INTEGER PRIMARY KEY AUTOINCREMENT
- bucket_name TEXT NOT NULL
- allocated_amount REAL NOT NULL DEFAULT 0.0
- target_amount REAL DEFAULT 0.0

## 6. Development Rules for Claude Code & Developers

- Stateless Dominance: Gunakan StatelessWidget untuk halaman utama (xxx_page.dart, xxx_mobile.dart, xxx_tablet.dart).
- Selective Micro-Rebuild: Hanya bungkus widget kecil yang berubah (seperti teks total saldo atau item list) dengan State Listener (Riverpod Consumer / Obx).
- Responsive Routing Pattern: Setiap xxx_page.dart wajib menggunakan LayoutBuilder untuk memisahkan xxx_mobile.dart (< 600dp) dan xxx_tablet.dart (>= 600dp).
