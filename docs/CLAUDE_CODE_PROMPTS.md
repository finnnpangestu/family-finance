# CLAUDE_CODE_PROMPTS.md - Step-by-Step CLI Execution Commands

Use these exact prompts in sequence when building the project using Claude Code CLI:

### Step 1: Project Setup & Core Configuration

claude "Initialize Flutter project structure according to PROJECT_STRUCTURE.md. Add sqflite, path, flutter_riverpod, google_fonts, fluentui_system_icons, googleapis, and google_sign_in to pubspec.yaml. Implement main.dart with textScaler locked to 1.0 and google_fonts theme as specified in DESIGN_SYSTEM.md."

### Step 2: Core Database & Design System

claude "Implement core database helper in lib/core/database/app_database.dart using sqflite with tables defined in PRD.md. Implement core design tokens in lib/core/theme/ with Google Fonts and fluentui_system_icons (Regular variants only) and global bottom sheet in lib/core/widgets/app_bottom_sheet.dart."

### Step 3: Central Dashboard Feature

claude "Build the dashboard feature in features/dashboard/. Create dashboard_page.dart with LayoutBuilder routing to dashboard_mobile.dart and dashboard_tablet.dart. Implement Income total aggregation (Income A + B) and quick action buttons for transaction slide-up bottom sheet using Fluent Icons Regular."

### Step 4: Expense & Income Input Bottom Sheets

claude "Implement slide-up form bottom sheets for adding income streams and expenses (lump-sum and itemized modes) using native numeric keyboard inputs."

### Step 5: Transaction History & Google Drive Backup

claude "Implement transaction history feature with split-view layout for tablets in features/transaction_history/. Add Google Drive backup export/import helper in features/backup_setting/ using appDataFolder."
