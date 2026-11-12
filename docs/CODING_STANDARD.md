# CODING_STANDARD.md - Code Style & Best Practices

## 1. Comments & Documentation Rules

- Language: Write all code comments in English.
- Verbosity: Keep comments concise and intentional. Explain why, not what.
- Formatting: DO NOT use large ASCII banner dividers such as // ============================================. Use clean single-line comments // Explanation here.

## 2. Widget & UI Rules

- Prefer StatelessWidget: Use StatelessWidget for pages and UI screens. Avoid StatefulWidget unless managing raw controller state like TextEditingController or animations.
- No Page-Wide setState: Never call setState() at the page level. Use localized state consumers or scoped builders.
- Fixed Font Scaler & Google Fonts: Ensure all text components respect textScaler: const TextScaler.linear(1.0) configured in main.dart and use google_fonts for typography.
- Icons Standard (fluentui_system_icons): Always use fluentui_system_icons package. Strictly select Regular variants only (e.g. FluentIcons.wallet_24_regular). Do NOT use Filled variants.
- Global Modal Bottom Sheets: Always use showAppBottomSheet() from core/widgets/app_bottom_sheet.dart for form popups.

## 3. Naming Conventions

- File names: snake_case.dart
- Class names: PascalCase
- Variable & method names: camelCase
- Constant names: lowerCamelCase or kCamelCase
- Feature page breakdown:
  - <feature>\_page.dart (Main entry point)
  - <feature>\_mobile.dart (Mobile layout)
  - <feature>\_tablet.dart (Tablet layout)
