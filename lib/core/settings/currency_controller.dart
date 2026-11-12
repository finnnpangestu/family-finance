import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/currency_formatter.dart';
import 'app_currency.dart';
import 'settings_store.dart';

// Read in main() before the first frame, so there is no "Rp" -> "$" flash.
final initialCurrencyProvider = Provider<AppCurrency>((_) => AppCurrency.idr);

final currencyControllerProvider =
    NotifierProvider<CurrencyController, AppCurrency>(CurrencyController.new);

class CurrencyController extends Notifier<AppCurrency> {
  @override
  AppCurrency build() => ref.read(initialCurrencyProvider);

  // Persists first; only switches the display once the write succeeded.
  Future<void> select(AppCurrency currency) async {
    if (currency == state) return;
    await ref
        .read(settingsStoreProvider)
        .write(SettingsStore.currencyCode, currency.code);
    CurrencyFormatter.use(currency);
    state = currency;
  }
}

// Money text is formatted through a static formatter, so after a currency
// switch every element under this scope is marked dirty once. Navigation
// state is kept, unlike rebuilding the app with a new key.
class CurrencyRefreshScope extends ConsumerWidget {
  const CurrencyRefreshScope({super.key, required this.child});

  final Widget child;

  static void _rebuildAll(Element element) {
    element
      ..markNeedsBuild()
      ..visitChildElements(_rebuildAll);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AppCurrency>(currencyControllerProvider, (_, _) {
      (context as Element).visitChildElements(_rebuildAll);
    });
    return child;
  }
}
