import 'package:flutter/material.dart';

/// Kindgerechtes Material-3-Theme: helle Farben, große Schrift, große Buttons.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF42A5F5); // freundliches Himmelblau

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    );
    const buttonText = TextStyle(fontSize: 22, fontWeight: FontWeight.bold);

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF3F9FF),
      // Alle Schriften 20 % größer als Standard.
      textTheme: base.textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        toolbarHeight: 72,
        titleTextStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: scheme.onPrimaryContainer,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(160, 64),
          textStyle: buttonText,
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(160, 64),
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(96, 56),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        extendedTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        extendedPadding: EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      ),
    );
  }
}
