import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'core/localization/shadcn_fallback_localizations.dart';
import 'core/utils/date_formatter.dart';
import 'features/dashboard/presentation/page/dashboard_page.dart';

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
  runApp(const ProviderScope(child: FFApp()));
}

class FFApp extends StatelessWidget {
  const FFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'FF',
      debugShowCheckedModeBanner: false,
      theme: const ThemeData(
        colorScheme: ColorSchemes.lightSlate,
        radius: 0.75,
      ),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      // Fallback must come first: ShadcnApp appends its en-only delegate last.
      localizationsDelegates: const [
        ShadcnFallbackLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      // Fixed scale keeps the elderly-tuned type sizes predictable.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const DashboardPage(),
    );
  }
}
