import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const _key = 'app_locale_code';
  Locale _locale = const Locale('fr', 'FR');

  Locale get locale => _locale;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_key);
    if (code == 'en') {
      _locale = const Locale('en', 'US');
    } else {
      _locale = const Locale('fr', 'FR');
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, locale.languageCode);
    notifyListeners();
  }
}
