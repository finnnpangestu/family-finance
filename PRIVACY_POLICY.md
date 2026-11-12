# Kebijakan Privasi — FF (Family Finance)

**Berlaku sejak:** 12 November 2026
**Terakhir diperbarui:** 12 November 2026

FF (Family Finance) ("Aplikasi", "kami") adalah aplikasi pencatatan keuangan keluarga yang bekerja **sepenuhnya offline**. Kebijakan ini menjelaskan data apa yang diproses Aplikasi, di mana data itu disimpan, dan kendali yang Anda miliki atasnya.

_English version below._

---

## 1. Ringkasan

- Semua catatan keuangan Anda **disimpan hanya di perangkat Anda**.
- Kami **tidak memiliki server**. Kami tidak menerima, melihat, atau menyimpan data Anda.
- Tidak ada iklan, analitik, pelacakan, atau penjualan data.
- Backup ke Google Drive **bersifat opsional** dan disimpan di akun Google Drive **milik Anda sendiri**.

## 2. Data yang Disimpan di Perangkat

Saat Anda memakai Aplikasi, data berikut disimpan di database lokal (SQLite) di perangkat Anda:

| Data         | Contoh                                                |
| ------------ | ----------------------------------------------------- |
| Pemasukan    | Sumber (mis. "Gaji Utama"), nominal, tanggal, catatan |
| Pengeluaran  | Kategori, nama item, nominal, tanggal, catatan        |
| Pos tabungan | Nama pos, jumlah dana, target                         |

Data ini tidak pernah dikirim ke kami atau pihak ketiga mana pun. Data hanya meninggalkan perangkat jika **Anda sendiri** menekan tombol backup ke Google Drive (lihat bagian 3).

## 3. Fitur Backup Google Drive (Opsional)

Jika Anda memilih masuk dengan akun Google untuk backup, Aplikasi menggunakan layanan Google Sign-In dan Google Drive API.

### Data Google yang diakses

| Data / izin                                 | Untuk apa                                                           | Disimpan di mana                     |
| ------------------------------------------- | ------------------------------------------------------------------- | ------------------------------------ |
| Alamat email & nama akun Google             | Ditampilkan di halaman Backup agar Anda tahu akun mana yang dipakai | Hanya di perangkat Anda (sesi login) |
| Izin `drive.appdata` (folder data aplikasi) | Menyimpan dan membaca **satu** file backup (`ff_backup.json`)       | Google Drive milik Anda              |

### Batasan akses

- Izin `drive.appdata` **hanya** memberi akses ke folder tersembunyi khusus Aplikasi ini. Aplikasi **tidak dapat** melihat, membaca, mengubah, atau menghapus file lain di Google Drive Anda.
- File backup berisi salinan data pada bagian 2 dalam format JSON. File ini dilindungi oleh keamanan akun Google Anda; Aplikasi tidak menambahkan enkripsi tersendiri.
- Data dikirim langsung dari perangkat Anda ke Google melalui koneksi terenkripsi (HTTPS). Data tidak melewati server kami.

### Penggunaan Terbatas (Limited Use)

Penggunaan dan pengiriman informasi yang diterima dari Google API oleh Aplikasi akan mematuhi [Kebijakan Data Pengguna Layanan API Google](https://developers.google.com/terms/api-services-user-data-policy), termasuk persyaratan Penggunaan Terbatas. Secara khusus, data Google Anda:

- hanya digunakan untuk menyediakan fitur backup dan pemulihan yang Anda minta;
- tidak dijual, tidak dipakai untuk iklan, dan tidak dibagikan ke pihak ketiga;
- tidak dibaca oleh manusia, dan tidak dipakai untuk melatih model AI/ML.

## 4. Izin Perangkat

Di Android, Aplikasi hanya meminta izin **Internet**, yang dipakai semata-mata untuk login Google dan backup Google Drive. Semua fitur lain berjalan tanpa koneksi internet. Aplikasi tidak mengakses lokasi, kontak, kamera, mikrofon, atau file pribadi Anda.

## 5. Pihak Ketiga

Satu-satunya layanan pihak ketiga yang digunakan adalah **Google** (Google Sign-In dan Google Drive), dan hanya ketika Anda menggunakan fitur backup. Penggunaan layanan tersebut juga tunduk pada [Kebijakan Privasi Google](https://policies.google.com/privacy).

Font dan aset lain sudah tertanam di dalam Aplikasi, sehingga Aplikasi tidak mengunduh apa pun dari internet saat dipakai.

## 6. Penyimpanan dan Penghapusan Data

Anda memegang kendali penuh atas data Anda:

| Yang ingin dilakukan                       | Caranya                                                                                   |
| ------------------------------------------ | ----------------------------------------------------------------------------------------- |
| Menghapus satu transaksi atau pos tabungan | Hapus langsung di dalam Aplikasi                                                          |
| Menghapus semua data di perangkat          | Hapus data Aplikasi di pengaturan HP, atau uninstall Aplikasi                             |
| Keluar dari akun Google di Aplikasi        | Halaman **Backup Google Drive → Keluar Akun**                                             |
| Menghapus file backup di Google Drive      | Google Drive (web) → **Setelan → Kelola aplikasi → FF → Hapus data aplikasi tersembunyi** |
| Mencabut akses Aplikasi ke akun Google     | [myaccount.google.com/permissions](https://myaccount.google.com/permissions)              |

Karena kami tidak menyimpan data Anda, kami tidak dapat memulihkan data yang sudah Anda hapus. Lakukan backup secara berkala.

## 7. Keamanan

Data lokal dilindungi oleh mekanisme keamanan sistem operasi perangkat Anda (penyimpanan privat aplikasi). Kami menyarankan Anda mengaktifkan kunci layar pada perangkat dan verifikasi 2 langkah pada akun Google Anda.

## 8. Privasi Anak

Aplikasi tidak ditujukan untuk anak di bawah 13 tahun dan tidak secara sengaja mengumpulkan data dari anak.

## 9. Perubahan Kebijakan

Jika kebijakan ini berubah, versi terbaru akan dipublikasikan di halaman ini dengan tanggal "Terakhir diperbarui" yang baru. Perubahan penting juga akan diinformasikan melalui pembaruan Aplikasi.

## 10. Kontak

Pertanyaan tentang kebijakan privasi ini dapat dikirim ke: **[alamat email kontak]**

---

---

# Privacy Policy — FF (Family Finance)

**Effective date:** November 12, 2026
**Last updated:** November 12, 2026

FF (Family Finance) ("the App", "we") is a family finance tracker that works **fully offline**. This policy explains what data the App handles, where it is stored, and the control you have over it.

## 1. Summary

- All of your financial records are **stored only on your device**.
- We **operate no servers**. We never receive, view, or store your data.
- No ads, analytics, tracking, or sale of data.
- Google Drive backup is **optional** and stored in **your own** Google Drive account.

## 2. Data Stored on Your Device

The App stores the following in a local SQLite database on your device:

| Data            | Examples                                        |
| --------------- | ----------------------------------------------- |
| Income          | Source (e.g. "Main Salary"), amount, date, note |
| Expenses        | Category, item name, amount, date, note         |
| Savings buckets | Bucket name, allocated amount, target           |

This data is never sent to us or to any third party. It leaves your device only when **you** choose to back it up to Google Drive (see section 3).

## 3. Google Drive Backup (Optional)

If you sign in with Google to use backup, the App uses Google Sign-In and the Google Drive API.

### Google data accessed

| Data / permission                               | Purpose                                                           | Where it is kept                      |
| ----------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------- |
| Google account email & name                     | Shown on the Backup screen so you know which account is connected | On your device only (sign-in session) |
| `drive.appdata` scope (application data folder) | Save and read **one** backup file (`ff_backup.json`)              | Your own Google Drive                 |

### Access limits

- The `drive.appdata` scope **only** grants access to a hidden folder reserved for this App. The App **cannot** see, read, modify, or delete any other file in your Google Drive.
- The backup file contains a copy of the data in section 2 in JSON format. It is protected by your Google account security; the App adds no separate encryption.
- Data travels directly from your device to Google over an encrypted (HTTPS) connection and never passes through our servers.

### Limited Use

The App's use and transfer of information received from Google APIs will adhere to the [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy), including the Limited Use requirements. In particular, your Google data:

- is used only to provide the backup and restore feature you request;
- is not sold, not used for advertising, and not shared with third parties;
- is not read by humans and is not used to train AI/ML models.

## 4. Device Permissions

On Android, the App requests only the **Internet** permission, used solely for Google sign-in and Google Drive backup. Every other feature works offline. The App does not access your location, contacts, camera, microphone, or personal files.

## 5. Third Parties

The only third-party service used is **Google** (Google Sign-In and Google Drive), and only when you use the backup feature. Its use is also subject to the [Google Privacy Policy](https://policies.google.com/privacy).

Fonts and other assets are bundled inside the App, so it downloads nothing from the internet during normal use.

## 6. Data Retention and Deletion

You are in full control of your data:

| To do this                                     | How                                                                           |
| ---------------------------------------------- | ----------------------------------------------------------------------------- |
| Delete a transaction or savings bucket         | Delete it inside the App                                                      |
| Delete all data on the device                  | Clear the App's data in your phone settings, or uninstall the App             |
| Sign out of Google in the App                  | **Backup Google Drive → Keluar Akun** (Sign out)                              |
| Delete the backup file in Google Drive         | Google Drive (web) → **Settings → Manage apps → FF → Delete hidden app data** |
| Revoke the App's access to your Google account | [myaccount.google.com/permissions](https://myaccount.google.com/permissions)  |

Because we do not store your data, we cannot recover data you have deleted. Please back up regularly.

## 7. Security

Local data is protected by your device operating system's security (app-private storage). We recommend enabling a screen lock on your device and 2-Step Verification on your Google account.

## 8. Children's Privacy

The App is not directed at children under 13 and does not knowingly collect data from children.

## 9. Changes to This Policy

If this policy changes, the updated version will be published on this page with a new "Last updated" date. Significant changes will also be announced through an App update.

## 10. Contact

Questions about this privacy policy can be sent to: **[contact email address]**
