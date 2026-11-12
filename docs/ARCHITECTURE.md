# ARCHITECTURE.md - Semi-Clean Architecture (Feature-First)

## 1. Architecture Overview

This application uses a Feature-First Semi-Clean Architecture. Code is grouped primarily by domain features (dashboard, transaction_history, backup_setting) rather than technical layers. This keeps features self-contained and simplifies maintenance.

## 2. Layer Definitions

### Data Layer (features/<feature>/data/)

- Data Sources: Handles raw SQLite operations using sqflite.
- Repositories: Converts raw database maps into strong typed Domain entities.

### Domain Layer (features/<feature>/domain/)

- Models / Entities: Pure Dart classes representing business concepts (Income, Expense, SavingsBucket).
- Value Objects / Math Helpers: Calculations like Total Income (Income A + Income B) and Free Balance remaining.

### Presentation Layer (features/<feature>/presentation/)

- Page Router (page/<feature>\_page.dart): Single entry point per feature using LayoutBuilder to route between Mobile and Tablet layouts. Holds initial controller initialization.
- Mobile Layout (page/<feature>\_mobile.dart): Single column layout (< 600dp).
- Tablet Layout (page/<feature>\_tablet.dart): Two-column layout (>= 600dp).
- Micro Widgets (widgets/): Reusable granular UI components that listen to state changes independently.

## 3. Dependency Rule

- Presentation depends on Domain & Data controllers.
- Domain depends on nothing (pure Dart).
- Data implements repositories specified by Domain.
