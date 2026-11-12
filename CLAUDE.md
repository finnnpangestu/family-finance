# CLAUDE.md - AI Entrance & Development Guidelines

This file serves as the main entry point for Claude Code CLI and AI assistants working on the Family Finance App repository.

## 1. Project Context & Philosophy

- Framework: Flutter (Latest Stable)
- Architecture: Semi-Clean Architecture (Feature-First)
- Target Devices: Android (Priority, low-end RAM 2GB support) & iOS (Prepared)
- Database: SQLite (sqflite) - Zero cloud backend cost, offline-first.
- Design System: Elderly-friendly UX, Shadcn Flutter styling, high contrast, fixed textScaler: 1.0.
- Typography: google_fonts package.
- Iconography: fluentui_system_icons package (Regular variants ONLY).

## 2. Documentation Map

Refer to the following .md files before generating code or modifying architecture:

- PRD.md: Full product requirement specifications, business logic, and database schemas.
- DESIGN_SYSTEM.md: Color tokens, typography (Google Fonts), icon standards (Fluent Icons Regular), modal bottom sheets, responsive breakpoints.
- AGENTS.md: Task routing and role definitions for AI sub-agents.
- ARCHITECTURE.md: Layering principles (Data, Domain, Presentation) & feature-first folder conventions.
- CODING_STANDARD.md: Code style, clean comments (English, concise), StatelessWidget rules, icon/font rules.
- PROJECT_STRUCTURE.md: Exact directory layout and file placement rules.
- STATE_MANAGEMENT.md: Riverpod state management implementation rules.

## 3. Strict Rules for Claude Code

- Stateless UI: Never create StatefulWidget for full screen pages. Use StatelessWidget with LayoutBuilder in xxx_page.dart and delegate UI to xxx_mobile.dart and xxx_tablet.dart.
- Micro-Rebuilding: Do not trigger page-wide rebuilds. Wrap only the exact dynamic UI element (e.g. balance text, transaction item card) in state listeners.
- Code Comments: Keep comments concise and in English. Never use heavy divider blocks like // ==========================.
- Text Scaling & Fonts: Ensure textScaler: const TextScaler.linear(1.0) is maintained in main.dart with google_fonts.
- Icon Selection: Use strictly Regular variants from fluentui_system_icons (e.g., FluentIcons.wallet_24_regular). Never use Filled variants.
- Forms & Input: All inputs must use global Modal Bottom Sheets with native Android numeric keyboard (TextInputType.number).
