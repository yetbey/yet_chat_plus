import 'package:flutter/material.dart';

/// Tema ile ilgili sabitleri içeren sınıf
class ThemeConstants {
  /// Bottom navigation bar teması
  static const BottomNavigationBarThemeData bottomNavigationBarTheme = BottomNavigationBarThemeData(
    selectedItemColor: Colors.purple,
    unselectedItemColor: Colors.grey,
    type: BottomNavigationBarType.fixed,
  );

  static const AppBarTheme appBarTheme = AppBarTheme(
      backgroundColor: Colors.black
  );

  static const Color darkScaffoldBackgroundColor = Colors.black;
  static const Color secondaryColor = Colors.grey;
}