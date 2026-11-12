# SPECS.md - FF (Family Finance) V1 Implementation Plan

Acuan: PRD.md, DESIGN_SYSTEM.md, ARCHITECTURE.md, STATE_MANAGEMENT.md, CODING_STANDARD.md, CLAUDE_CODE_PROMPTS.md.

## 1. Scope V1

| Step | Fitur                                                                                  | Status                    |
| ---- | -------------------------------------------------------------------------------------- | ------------------------- |
| 1    | Setup project, dependencies, `main.dart` (textScaler 1.0, Google Fonts)                | V1                        |
| 2    | SQLite (`incomes`, `expenses`, `savings_buckets`), design tokens, `showAppBottomSheet` | V1                        |
| 3    | Dashboard (F-01) + Multi-stream income (F-02)                                          | V1                        |
| 4    | Form pemasukan & pengeluaran mode Cepat/Rinci (F-03)                                   | V1                        |
| 5    | Riwayat adaptif (F-05) + Backup Google Drive appDataFolder                             | V1                        |
| -    | Pos Tabungan (F-04) — dirujuk dari Quick Actions dashboard                             | V1                        |
| -    | Voice-to-text (F-06)                                                                   | Ditunda (opsional di PRD) |

## 2. User Flow

1. **Dashboard** (satu-satunya hub, tanpa Bottom Navbar)
   - Header: Total Pemasukan bulan ini + rincian per sumber (Gaji Utama, Usaha, ...).
   - 3 kartu indikator: Masuk (hijau, bulan ini), Keluar (merah, bulan ini), Sisa Saldo Bebas (biru, kumulatif).
   - Quick Actions: Tambah Transaksi, Riwayat, Pos Tabungan, Backup Google Drive.
2. **Tambah Transaksi** → bottom sheet pilihan (Pemasukan / Pengeluaran) → bottom sheet form.
   - Pemasukan: sumber (chip dari kategori yang sudah ada + bisa ketik baru), nominal, tanggal, catatan.
   - Pengeluaran Cepat: nominal total harian, tanggal, catatan (kategori `Pengeluaran Harian`).
   - Pengeluaran Rinci: kategori + daftar item (nama + nominal), disimpan atomik dalam 1 transaksi DB.
   - Setelah simpan: sheet tertutup, snackbar sukses, dashboard/riwayat/tabungan auto-refresh.
3. **Riwayat**: filter bulan (◀ ▶) & kategori. Mobile: list (tinggi min 72dp), tap → detail di bottom sheet. Tablet: split view (kiri list, kanan detail + grafik pengeluaran per kategori). Hapus transaksi dengan konfirmasi.
4. **Pos Tabungan**: buat pos (nama, target opsional), isi dana (dibatasi Sisa Saldo Bebas), ambil dana, hapus pos (dana kembali ke saldo bebas).
5. **Backup**: login Google → Backup (upload JSON ke appDataFolder, overwrite file `ff_backup.json`) / Pulihkan (konfirmasi, data lokal diganti) / Keluar akun.

## 3. Aturan Bisnis

- `freeBalance = Σincome(all) − Σexpense(all) − Σallocated(buckets)`. Saldo bebas bersifat kumulatif agar konsisten dengan pos tabungan yang tidak punya tanggal.
- Masuk/Keluar pada kartu = bulan berjalan.
- Alokasi ke pos tidak boleh melebihi saldo bebas; ambil dana tidak boleh melebihi isi pos.
- Tanggal disimpan `yyyy-MM-dd` (sortable string); urut `date DESC, id DESC`.

## 4. Dependencies

| Package                                                                      | Alasan                                                                                           |
| ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| sqflite, path                                                                | Penyimpanan offline-first sesuai PRD                                                             |
| flutter_riverpod                                                             | State management (pakai `Notifier` API — kompatibel ke Riverpod 3; `StateNotifier` sudah legacy) |
| google_fonts                                                                 | Typography Plus Jakarta Sans                                                                     |
| fluentui_system_icons                                                        | Ikon (Regular only)                                                                              |
| google_sign_in (v7), googleapis, extension_google_sign_in_as_googleapis_auth | Backup Drive appDataFolder                                                                       |
| intl, flutter_localizations                                                  | Format Rupiah & tanggal Indonesia, date picker lokal                                             |
| equatable                                                                    | Model immutable dengan value equality (efektif untuk `select`)                                   |
| sqflite_common_ffi (dev)                                                     | Unit test database di desktop                                                                    |

## 5. Keputusan Implementasi (deviasi dari dokumen)

- **Riverpod `Notifier`** dipakai, bukan `StateNotifierProvider` di STATE_MANAGEMENT.md: `StateNotifier` sudah legacy; pola `select` + state immutable tetap sama. Riverpod 2.6.1 (versi tertinggi yang kompatibel dengan Flutter 3.41.9 terpasang).
- **Fitur `savings_bucket/`** ditambahkan di `features/` karena Quick Actions PRD F-01 menunjuk ke SavingsBucketPage, tetapi tidak ada di PROJECT_STRUCTURE.md.
- **Entity Income/Expense** ada di `features/dashboard/domain/` dan dipakai ulang oleh fitur lain.
- **Font dibundel** di `assets/google_fonts/` + `allowRuntimeFetching = false` agar tetap offline-first.
- **Sinkronisasi antar fitur** lewat `financeRevisionProvider` (counter) — tiap write menaikkan revisi, controller lain me-refresh via `ref.listen`.
- **Izin INTERNET** ditambahkan ke manifest utama Android (template Flutter hanya memasangnya untuk debug) agar backup jalan di release.

## 6. Edge-Case & Failure Handling

- **Validasi form**: nominal wajib > 0, sumber/kategori wajib, minimal 1 item valid di mode Rinci. Tombol simpan nonaktif saat proses (cegah double submit).
- **DB error**: setiap operasi async di try/catch; controller menyimpan `errorMessage`, UI menampilkan state error + tombol "Coba Lagi"; snackbar gagal untuk aksi tulis.
- **Input angka**: `TextInputType.number` + formatter digit-only dengan pemisah ribuan; batas 15 digit untuk mencegah overflow.
- **Backup**:
  - Belum dikonfigurasi OAuth (`GOOGLE_SERVER_CLIENT_ID`) / platform tak didukung → pesan jelas.
  - User batal login / tolak izin → kembali ke state idle tanpa error menakutkan.
  - Network error / API error → pesan "Periksa koneksi internet".
  - File backup tidak ada saat restore → info "Belum ada backup".
  - JSON rusak / versi skema lebih baru → tolak restore, data lokal tidak disentuh (restore dalam 1 transaksi DB → rollback otomatis).
- **Hapus data**: selalu lewat dialog konfirmasi.
- **Cleanup**: TextEditingController di-dispose; listener auth Google dibatalkan via `ref.onDispose`.

## 7. Dashboard v2 — Layout Modern + Grafik Arus Kas

**User flow (urutan mobile, atas → bawah):**

1. Top bar: sapaan sesuai jam ("Selamat pagi/siang/sore/malam"), judul "Keuangan", tanggal, logo.
2. Kartu hero gelap: **Sisa Saldo Bebas** (angka terbesar) + dua tile Masuk / Keluar bulan ini (memenuhi indikator F-01).
3. Grid aksi cepat 4 tombol (Tambah, Riwayat, Tabungan, Backup) — tiap target ≥ 72dp, label 14pt+.
4. Kartu **Arus Kas 6 Bulan**: grouped bar chart pemasukan vs pengeluaran per bulan. Tap kolom bulan → readout nilai bulan itu + selisih. Default: bulan berjalan.
5. Kartu **Sumber Pemasukan**: total income bulan ini (Income A + B) + bar proporsi per sumber.
   Tablet: kiri hero + aksi + sumber pemasukan, kanan grafik.

**Data:** `FinanceRepository.monthlyCashflow(months: 6)` → 2 query `GROUP BY substr(date,1,7)` (tanpa tabel baru). Masuk ke `DashboardState.cashflow`, di-refresh bersama ringkasan.

**Grafik (dataviz skill):** satu sumbu Y, bar tipis ujung atas membulat 4px, celah 2px antar bar, gridline samar, legenda selalu ada (2 seri), nilai di readout bukan di tiap bar. Warna divalidasi: `#166534` (masuk) + `#F87171` (keluar) lolos semua cek (CVD ΔE 16.1); merah-800 lama gagal (ΔE 4.0). Teks memakai warna teks, bukan warna seri. Alternatif teks via `Semantics` berisi semua nilai.

**Dependencies:** tidak ada — chart pakai `CustomPainter` (ringan untuk RAM 2GB).

**Edge cases:** semua bulan 0 → empty state; nilai sangat besar → label sumbu ringkas (rb/jt/M); gagal muat → banner error yang sudah ada, angka terakhir tetap tampil.

## 8. Pengaturan Mata Uang + Perbaikan Sesi Backup

**User flow:**

- Dashboard top bar → ikon ⚙️ → halaman **Pengaturan** → bagian **Mata Uang** (daftar pilihan besar, ketuk untuk memilih) → toast konfirmasi. Semua angka di seluruh app langsung berganti simbol tanpa restart & tanpa keluar dari halaman.
- Pilihan: IDR (default), USD, EUR, SGD, MYR, SAR, JPY, AUD, GBP, CNY.
- **Tidak ada konversi kurs** — hanya simbol tampilan; dijelaskan di UI. Input tetap bilangan bulat (tanpa desimal) agar konsisten dengan form yang ada.

**Penyimpanan:** tabel baru `app_settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)` lewat migrasi SQLite v1 → v2 (`onUpgrade`). Tidak ikut backup Drive (preferensi per perangkat). Mata uang dibaca di `main()` sebelum frame pertama supaya tidak berkedip "Rp" → "$".

**Sesi backup (bug):** controller backup sebelumnya `autoDispose`, jadi setiap buka halaman dimulai ulang dan memanggil silent sign-in Google lagi. Perbaikan:

1. Controller dibuat hidup selama app berjalan → state akun & info backup terakhir dipakai ulang saat halaman dibuka lagi.
2. Flag `backup_signed_in` disimpan; silent sign-in hanya dicoba **sekali per peluncuran app** dan hanya jika user pernah login.
3. Service mengembalikan akun yang sudah ada di memori tanpa memanggil Google lagi.

**Edge cases:** gagal baca/tulis setting → tetap IDR + toast error; sesi Google kedaluwarsa → flag dihapus, tampil tombol "Masuk" biasa; backup lama (schema v1) tetap bisa dipulihkan ke DB v2.

## 9. Data Terpisah per Akun Google (Profil)

**Masalah:** semua akun Google memakai satu database yang sama, jadi ganti akun tetap menampilkan transaksi akun sebelumnya.

**Desain:** satu file SQLite per akun + satu profil "HP ini" (tanpa akun).

- `ff_family_finance.db` = profil HP ini (file lama, tanpa migrasi) **dan** tempat pengaturan perangkat (`app_settings`: mata uang, akun aktif).
- `ff_acct_<hash>.db` = data milik satu akun Google. Nama file memakai hash email (email tidak tertulis di nama file).
- Akun aktif disimpan di pengaturan → saat app dibuka data langsung tampil walau offline / sesi Google kedaluwarsa.

**User flow:**

1. Belum login → data profil HP ini.
2. Login akun A pertama kali di HP ini:
   - HP ini punya catatan → dialog: "Pindahkan catatan di HP ini ke akun A?" → _Pindahkan_ (data pindah ke A, profil HP ini kosong) / _Mulai kosong_.
   - Jika akun A punya backup di Drive dan profilnya baru → pesan: tekan "Pulihkan dari Drive".
3. Login akun A lagi (profil sudah ada) → langsung pakai data A.
4. Keluar akun (konfirmasi) → kembali ke data HP ini; data A tetap tersimpan dan muncul lagi saat masuk.
5. Masuk akun B → data B (kosong bila baru). Backup/restore Drive selalu untuk profil aktif.

**Teknis:** `deviceDatabaseProvider` (tetap) + `activeAccountProvider`; `appDatabaseProvider` diturunkan dari akun aktif sehingga semua repository otomatis pindah. Setelah ganti profil, `financeRevisionProvider` di-bump agar dashboard/riwayat/tabungan memuat ulang. Pemindahan data: salin semua baris ke profil akun dalam satu transaksi (id dibuat ulang agar tidak bentrok), baru kemudian profil HP ini dikosongkan.

**Edge cases:** pemindahan gagal → profil tidak diganti, data HP ini utuh; sesi Google kedaluwarsa → data akun tetap tampil (offline-first), cukup login ulang; user lama yang sudah login sebelum update cukup login sekali lagi lalu memilih "Pindahkan".

**Sapaan dashboard:** "Selamat pagi/siang/sore/malam, <nama depan akun Google>"; nama disimpan di pengaturan agar tampil offline, tanpa akun → sapaan saja.

## 10. Fitur Lanjutan: Anggaran, Transaksi Rutin, Laporan, Anggota, Pengingat, Kategori

### Database v3 (migrasi `onUpgrade`, data lama utuh)

| Tabel / kolom                                                                                                         | Isi                                                               |
| --------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `categories(id, type, name)` UNIQUE(type,name)                                                                        | Kategori pemasukan/pengeluaran; diisi default saat create/upgrade |
| `family_members(id, name UNIQUE)`                                                                                     | Anggota keluarga                                                  |
| `incomes.member_id`, `expenses.member_id`                                                                             | Opsional, NULL = tanpa anggota                                    |
| `budgets(id, category_name UNIQUE, monthly_limit)`                                                                    | Batas pengeluaran per kategori per bulan                          |
| `recurring_transactions(id, type, category_name, item_name, amount, day_of_month, next_due, note, member_id, active)` | Aturan transaksi rutin bulanan                                    |

Semua tabel baru ikut backup Drive & pemindahan data ke akun. Daftar kolom backup dipindah ke satu sumber (`AppDatabase.backupColumns`).

### User flow

- **Anggaran:** Dashboard → kartu "Anggaran Bulan Ini" (progres per kategori; ≥80% kuning "hampir habis", ≥100% merah "melebihi") → "Atur" → halaman Anggaran (tambah/ubah/hapus batas). Setelah menyimpan pengeluaran yang membuat kategori melewati 80%/100% → toast peringatan (+ notifikasi bila diaktifkan).
- **Transaksi rutin:** di form pemasukan/pengeluaran (mode cepat & per item kategori) ada sakelar "Ulangi tiap bulan (tgl X)". Disimpan sebagai aturan + transaksi pertama. Saat app dibuka, semua jatuh tempo s/d hari ini dibuat otomatis (termasuk bulan yang terlewat). Kelola/hentikan di Pengaturan → Transaksi Rutin. Tanggal 29–31 jatuh ke hari terakhir bulan pendek.
- **Laporan bulanan:** Riwayat → "Bagikan Laporan" → PDF bulan yang dipilih (ringkasan masuk/keluar/selisih, pengeluaran per kategori, status anggaran, daftar transaksi) → share sheet (WhatsApp, email, simpan).
- **Anggota keluarga:** Pengaturan → Anggota (tambah/hapus). Form transaksi: pilih anggota (opsional). Riwayat: filter per anggota; detail menampilkan anggota. Hapus anggota → transaksinya menjadi "tanpa anggota".
- **Pengingat:** Pengaturan → Pengingat: sakelar pengingat harian + jam; sakelar peringatan anggaran. Izin notifikasi diminta saat sakelar dinyalakan.
- **Kategori custom:** Pengaturan → Kategori (tab Pemasukan/Pengeluaran): tambah & hapus. Chip di form diambil dari daftar ini; mengetik kategori baru di form otomatis menambahkannya.

### Dependencies baru

| Package                                                         | Alasan                                                                        |
| --------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `pdf`                                                           | Membuat PDF laporan secara lokal (offline)                                    |
| `share_plus`                                                    | Share sheet native untuk file laporan                                         |
| `path_provider`                                                 | Folder sementara untuk file PDF                                               |
| `flutter_local_notifications` + `timezone` + `flutter_timezone` | Pengingat harian terjadwal di zona waktu lokal & alert anggaran, tanpa server |

### Edge cases

- Generasi transaksi rutin idempoten: memakai `next_due` dan berjalan dalam satu transaksi DB → tidak dobel walau app dibuka berkali-kali.
- Izin notifikasi ditolak → sakelar kembali mati + pesan.
- Hapus kategori tidak menghapus transaksi lama (kategori tersimpan sebagai teks).
- Laporan bulan kosong tetap dibuat (berisi ringkasan nol). Gagal membuat/berbagi → toast error.
