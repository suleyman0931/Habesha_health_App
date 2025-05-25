import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_am.dart';

class AppLocalizations {
  final BuildContext? context;

  AppLocalizations(this.context);

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(context);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  String translate(String key) {
    Locale? currentLocale = context != null ? Localizations.localeOf(context!) : null;
    if (currentLocale?.languageCode == 'am') {
      return appLocalizationsAm[key] ?? key;
    } else {
      return appLocalizationsEn[key] ?? key;
    }
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'am'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(null);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}