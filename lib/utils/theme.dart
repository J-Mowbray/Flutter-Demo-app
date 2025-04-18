import 'package:flutter/material.dart';

/// Centralised theme configuration for the weather application.
///
/// Provides consistent theming across the application with predefined
/// light and dark themes. Both themes share similar structural properties
/// but with appropriate brightness and colour adjustments.
class AppTheme {
  /// Light theme configuration for daytime and bright environment usage.
  ///
  /// Features a blue-based colour scheme with light backgrounds and
  /// appropriately contrasting text for optimal readability in well-lit conditions.
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Color.fromARGB(248, 192, 171, 171),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
    ),
  );

  /// Dark theme configuration for nighttime and low-light environment usage.
  ///
  /// Utilises darker backgrounds with appropriate text contrast to reduce
  /// eye strain in dimly lit conditions while maintaining the application's
  /// visual identity and usability.
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
    ),
  );
}
