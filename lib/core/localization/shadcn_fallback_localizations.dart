import 'package:flutter/foundation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

// shadcn_flutter ships English strings only. This delegate accepts any locale
// (e.g. id_ID) and serves English, so Material/Cupertino can stay Indonesian.
class ShadcnFallbackLocalizationsDelegate
    extends LocalizationsDelegate<ShadcnLocalizations> {
  const ShadcnFallbackLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<ShadcnLocalizations> load(Locale locale) =>
      SynchronousFuture(lookupShadcnLocalizations(const Locale('en')));

  @override
  bool shouldReload(ShadcnFallbackLocalizationsDelegate old) => false;
}
