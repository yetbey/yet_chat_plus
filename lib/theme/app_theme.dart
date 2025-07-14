import 'package:flutter/material.dart';

class AppTheme {
  /// Açık Tema Renk ve Stil Ayarları
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: Colors.black54,
      scaffoldBackgroundColor: Colors.grey.shade100, // Sayfa arka planı
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // AppBar ikon ve başlık rengi
        elevation: 0,
        centerTitle: true,
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.black54, // Ana renk (butonlar, vurgular)
        secondary: Colors.white70, // İkincil renk
        surface: Colors.white, // Kart gibi yüzeylerin rengi
        onPrimary: Colors.white, // Ana rengin üzerindeki yazı/ikon rengi
        onSecondary: Colors.black, // İkincil rengin üzerindeki yazı/ikon
        tertiary: Colors.grey.shade700,
        onTertiary: Colors.white70,
        onSurface: Colors.black, //
        primaryContainer: Colors.white70,
        secondaryContainer: Colors.black54, // Yüzeylerin üzerindeki yazı/ikon
      ),
      listTileTheme: ListTileThemeData(tileColor: Colors.white70),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.black, // Seçili sekmenin rengi
        unselectedLabelColor: Colors.grey, // Seçili olmayan sekmenin rengi
        indicatorColor: Colors.black54, // Altındaki çizginin rengi
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(Colors.black54),
          textStyle: WidgetStateProperty.all(
            TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.all(Colors.grey.shade300),
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black; // Açıkken topun rengi
          }
          return Colors.grey.shade200; // Kapalıyken topun rengi
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.grey.shade700; // Açıkken yolun rengi
          }
          return Colors.grey.shade400; // Kapalıyken yolun rengi
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.blue.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // Butonun arka plan rengi
          foregroundColor: Colors.white, // Buton üzerindeki yazı ve ikon rengi
          elevation: 1, // Butonun gölge yüksekliği
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Köşeleri yuvarlat
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: Colors.black87),
        labelLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ), // ElevatedButton içindeki yazı
      ),
    );
  }

  /// Koyu Tema Renk ve Stil Ayarları
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: Colors.purple,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      colorScheme: ColorScheme.dark(
        primary: Colors.white70,
        secondary: Colors.black54,
        surface: Colors.black12,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        tertiary: Colors.white70,
        onTertiary: Colors.grey.shade700,
        primaryContainer: Colors.black54,
        secondaryContainer: Colors.white70,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade800.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.tealAccent),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade400),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple, // Butonun arka plan rengi
          foregroundColor:
              Colors.white70, // Buton üzerindeki yazı ve ikon rengi
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white, // Seçili sekmenin rengi
        unselectedLabelColor: Colors.grey, // Seçili olmayan sekmenin rengi
        indicatorColor: Colors.white70, // Altındaki çizginin rengi
      ),
      listTileTheme: ListTileThemeData(tileColor: Colors.black),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(Colors.white70),
          textStyle: WidgetStateProperty.all(
            TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.all(Colors.grey.shade700),
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.grey.shade600; // Açıkken topun rengi
          }
          return Colors.grey.shade600; // Kapalıyken topun rengi
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.grey.shade600; // Açıkken yolun rengi
          }
          return Colors.grey.shade800; // Kapalıyken yolun rengi
        }),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: Colors.white70),
        labelLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }
}
