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
