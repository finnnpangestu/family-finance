# PROJECT_STRUCTURE.md - Directory & File Layout

```
family_finance_app/
├── android/
├── ios/
├── assets/
│   ├── icons/
│   └── images/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart
│   │   │   └── tables/
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   └── app_theme.dart
│   │   ├── utils/
│   │   │   ├── currency_formatter.dart
│   │   │   └── date_formatter.dart
│   │   └── widgets/
│   │       ├── app_bottom_sheet.dart
│   │       └── app_button.dart
│   │
│   └── features/
│       ├── dashboard/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │       ├── controllers/
│       │       ├── widgets/
│       │       └── page/
│       │           ├── dashboard_page.dart
│       │           ├── dashboard_mobile.dart
│       │           └── dashboard_tablet.dart
│       │
│       ├── transaction_history/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │       ├── controllers/
│       │       ├── widgets/
│       │       └── page/
│       │           ├── history_page.dart
│       │           ├── history_mobile.dart
│       │           └── history_tablet.dart
│       │
│       └── backup_setting/
│           ├── data/
│           ├── domain/
│           └── presentation/
│               ├── controllers/
│               └── page/
│                   ├── backup_page.dart
│                   ├── backup_mobile.dart
│                   └── backup_tablet.dart
└── pubspec.yaml
```
