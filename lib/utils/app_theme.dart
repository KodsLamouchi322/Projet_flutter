// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const primaryOrange = Color(0xFFE65100);
  static const accentBlue = Color(0xFF1565C0);
  static const bgDark = Color(0xFF121212);
  static const cardDark = Color(0xFF1E1E1E);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryOrange),
    appBarTheme: const AppBarTheme(backgroundColor: primaryOrange, foregroundColor: Colors.white, elevation: 0),
    cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    cardColor: cardDark,
    colorScheme: ColorScheme.dark(primary: primaryOrange, secondary: accentBlue),
  );
}
