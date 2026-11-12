import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'core/database/app_database.dart';
import 'core/database/database_providers.dart';
import 'core/localization/shadcn_fallback_localizations.dart';
import 'core/settings/app_currency.dart';
import 'core/settings/currency_controller.dart';
import 'core/settings/settings_store.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/currency_formatter.dart';
import 'core/utils/date_formatter.dart';
import 'features/dashboard/presentation/page/dashboard_page.dart';
import 'features/reminders/presentation/reminder_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // Fonts ship in assets/google_fonts so the app never needs the network.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle.loadString(
      'assets/google_fonts/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  await initializeDateFormatting(DateFormatter.locale);
  // Light UI everywhere: dark status/navigation bar icons.
  SystemChrome.setSystemUIOverlayStyle(FFApp.systemBars);

  final AppDatabase deviceDb = AppDatabase();
  final SettingsStore settings = SettingsStore(deviceDb);
  final AppCurrency currency = await _loadCurrency(settings);
  final AccountProfile? account = await _loadActiveAccount(settings);
  CurrencyFormatter.use(currency);

  final ProviderContainer container = ProviderContainer(
    overrides: [
      deviceDatabaseProvider.overrideWithValue(deviceDb),
      initialCurrencyProvider.overrideWithValue(currency),
      initialActiveAccountProvider.overrideWithValue(account),
    ],
  );
  runApp(UncontrolledProviderScope(container: container, child: const FFApp()));

  // After the first frame is queued: reminders never delay startup.
  unawaited(
    container.read(reminderControllerProvider.notifier).restoreSchedule(),
  );
}

// A failed read must never block startup; Rupiah is the safe default.
Future<AppCurrency> _loadCurrency(SettingsStore settings) async {
  try {
    return AppCurrency.fromCode(
      await settings.read(SettingsStore.currencyCode),
    );
  } catch (error) {
    debugPrint('Currency setting unavailable: $error');
    return AppCurrency.idr;
  }
}

// Falls back to the device profile if settings cannot be read.
Future<AccountProfile?> _loadActiveAccount(SettingsStore settings) async {
  try {
    final String? email = await settings.read(SettingsStore.activeAccount);
    if (email == null) return null;
    return AccountProfile(
      email: email,
      displayName: await settings.read(SettingsStore.activeAccountName),
    );
  } catch (error) {
    debugPrint('Active account unavailable: $error');
    return null;
  }
}

class FFApp extends StatelessWidget {
  const FFApp({super.key});

  // Pages have white backgrounds and no AppBar, so the system bars must be
  // told explicitly to use dark icons, or they vanish into the white.
  static const SystemUiOverlayStyle systemBars = SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    statusBarIconBrightness: Brightness.dark, // Android
    statusBarBrightness: Brightness.light, // iOS
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: AppColors.border,
  );

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'FF',
      debugShowCheckedModeBanner: false,
      theme: const ThemeData(colorScheme: AppTheme.shadcnColors, radius: 0.75),
      // Dialogs, date picker and text fields are Material widgets.
      materialTheme: AppTheme.light,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      // Fallback must come first: ShadcnApp appends its en-only delegate last.
      localizationsDelegates: const [
        ShadcnFallbackLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      // Fixed scale keeps the elderly-tuned type sizes predictable.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        // Re-applied on every frame so no route can reset it to light icons.
        value: systemBars,
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: CurrencyRefreshScope(child: child ?? const SizedBox.shrink()),
        ),
      ),
      home: const DashboardPage(),
    );
  }
}
