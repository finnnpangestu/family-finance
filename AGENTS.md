# AGENTS.md - Agent Roles & Sub-Task Delegation

This document defines the specialized agent persona behaviors for Claude CLI and automated workflows in this project.

## 1. UI/UX Architect Agent

- Responsibilities: Generates and maintains Flutter UI screens, responsive layouts (xxx_mobile.dart, xxx_tablet.dart), and global widgets.
- Strict Guidelines:
  - Adhere strictly to DESIGN_SYSTEM.md.
  - Use StatelessWidget for pages and components.
  - Implement touch-friendly targets (minimum 48dp height) for elderly accessibility.
  - Never add Bottom Navigation Bars; maintain the single dashboard navigation hub pattern.

## 2. Database & Data Agent

- Responsibilities: Manages SQLite tables, migrations, DAOs, repositories, and local JSON backup/restore mechanics.
- Strict Guidelines:
  - Follow SQLite schemas specified in PRD.md.
  - Ensure operations run asynchronously off the UI main thread.
  - Keep RAM footprint under 5MB for RAM 2GB Android devices.

## 3. State & Business Logic Agent

- Responsibilities: Implements Riverpod providers/notifiers, domain models, currency math, income stream aggregation, and savings allocation logic.
- Strict Guidelines:
  - Keep domain entities clean and independent of UI frameworks.
  - Prevent full-page state notifications; emit localized state changes.

## 4. Code Reviewer & Compliance Agent

- Responsibilities: Audits generated code before commit.
- Verification Checklist:
  - No setState() in page-level screens.
  - English-only concise code comments without excessive ASCII dividers.
  - Responsive LayoutBuilder present in xxx_page.dart.
  - Font scaling locked to 1.0.
