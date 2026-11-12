# DESIGN_SYSTEM.md - Family Finance App (Shadcn Flutter & Fluent Icons Theme)

Dokumen ini berisi standar Design System dan UX Guidelines yang dirancang khusus untuk kemudahan orang tua (Elderly-Friendly UX), performa tinggi pada perangkat spek rendah (RAM 2GB), dan adaptabilitas layar Mobile & Tablet.

## 1. Global Text Scaling & Typography (Google Fonts)

Semua typography aplikasi menggunakan package google_fonts (misal: GoogleFonts.plusJakartaSans atau GoogleFonts.inter) dengan konfigurasi pengunci skala teks di main.dart:

### Main.dart Font & Scaling Lock Configuration

```dart
MaterialApp(
  theme: ThemeData(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    ),
  ),
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0), // Force 1.0 text scaling
      ),
      child: child!,
    );
  },
);
```

### Type Scale (Elderly-Friendly Minimum Sizes)

| Style Name     | Font Size | Line Height | Weight         | Usage                          |
| -------------- | --------- | ----------- | -------------- | ------------------------------ |
| Display Large  | 32pt      | 40pt        | Bold (700)     | Main Balance / Total Income    |
| Heading Large  | 24pt      | 32pt        | SemiBold (600) | Page Headers, Modal Titles     |
| Heading Medium | 20pt      | 28pt        | SemiBold (600) | Section Titles, Card Headers   |
| Body Large     | 18pt      | 26pt        | Regular (400)  | Primary List Items, Inputs     |
| Body Medium    | 16pt      | 24pt        | Regular (400)  | Subtitles, Secondary Text      |
| Caption        | 14pt      | 20pt        | Medium (500)   | Badges, Helper Text (Min Size) |

Catatan: Ukuran font terkecil di aplikasi ini diset minimal 14pt agar tetap terbaca jelas oleh orang tua.

## 2. Iconography Standard (fluentui_system_icons)

Seluruh ikon dalam aplikasi wajib menggunakan package fluentui_system_icons.

### Strict Icon Rules:

- Regular Variant Only: HANYA boleh menggunakan varian Regular (misalnya FluentIcons.wallet_24_regular, FluentIcons.add_24_regular).
- Dilarang: Menggunakan varian Filled (\_filled) agar visual konsisten, bersih, dan kontras tinggi.
- Icon Sizing:
  - Small / Inline: 20_regular
  - Standard / Button: 24_regular
  - Large / Action Header: 32_regular atau 48_regular

## 3. Color Palette (High-Contrast Accessibility - WCAG AAA)

Warna menggunakan token dasar Shadcn Slate/Emerald dengan rasio kontras tinggi:

```dart
class AppColors {
  // Brand & Financial Indicators
  static const Color primary = Color(0xFF0F172A);      // Slate 900
  static const Color income = Color(0xFF166534);       // Emerald 800 (Pemasukan - Kontras Tinggi)
  static const Color expense = Color(0xFF991B1B);      // Red 800 (Pengeluaran - Kontras Tinggi)
  static const Color savings = Color(0xFF1E40AF);      // Blue 800 (Tabungan/Pos)

  // Backgrounds & Cards
  static const Color background = Color(0xFFF8FAFC);   // Slate 50
  static const Color card = Color(0xFFFFFFFF);         // Pure White
  static const Color muted = Color(0xFFF1F5F9);        // Slate 100

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);  // Slate 900
  static const Color textSecondary = Color(0xFF475569);// Slate 600
  static const Color textMuted = Color(0xFF94A3B8);    // Slate 400

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);       // Slate 200
}
```

## 4. Global Modal Bottom Sheet Standard (Slide-Up Form)

Seluruh form input (Tambah Pemasukan/Pengeluaran/Tabungan) wajib menggunakan Modal Bottom Sheet Global agar konsisten dan ramah jempol (Thumb-Friendly).

```dart
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.headingLarge),
          const SizedBox(height: 16),
          Flexible(child: child),
        ],
      ),
    ),
  );
}
```

## 5. Layout Breakpoints (Mobile vs Tablet)

| Device Class | Breakpoint Width | Layout Strategy                                  | File Structure  |
| ------------ | ---------------- | ------------------------------------------------ | --------------- |
| Mobile       | < 600 dp         | Single Column, Vertical Scroll, Full-Width Cards | xxx_mobile.dart |
| Tablet       | >= 600 dp        | Two Column / Grid System, Side-by-Side Detail    | xxx_tablet.dart |

## 6. Micro-Rebuild Component Rules

- Dilarang memanggil setState() pada level Page/Screen.
- Form Input wajib dibungkus widget Form dan komponen input individu yang mendengarkan perubahan lokal.
- Widget tombol, kartu transaksi, dan indikator angka dipisah menjadi komponen independen di folder presentation/widgets/.
