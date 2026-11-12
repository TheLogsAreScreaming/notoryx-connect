import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

/// Translations for code that runs outside a screen, such as services and
/// notifications. The app sets the language whenever it rebuilds; until then,
/// and for unsupported languages, text is English.
abstract final class BastionText {
  static AppLocalizations _current = lookupAppLocalizations(const Locale('en'));

  static AppLocalizations get l => _current;

  static void use(Locale locale) {
    try {
      _current = lookupAppLocalizations(locale);
    } catch (_) {
      _current = lookupAppLocalizations(const Locale('en'));
    }
  }
}
