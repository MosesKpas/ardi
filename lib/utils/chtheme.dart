import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData => _isDarkMode ? darkTheme : lightTheme;

  static final lightTheme = ThemeData(
    primaryColor: const Color.fromRGBO(204, 20, 205, 100),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: const Color.fromRGBO(204, 20, 205, 100),
      secondary: Colors.purpleAccent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
        foregroundColor: Colors.white,
      ),
    ),
  );

  static final darkTheme = ThemeData(
    primaryColor: const Color.fromRGBO(204, 20, 205, 100),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: const Color.fromRGBO(204, 20, 205, 100),
      secondary: Colors.purpleAccent,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(204, 20, 205, 100),
        foregroundColor: Colors.white,
      ),
    ),
  );

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}