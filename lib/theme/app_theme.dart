import 'package:flutter/material.dart';

class AppTheme {
  /// Açık Tema Renk ve Stil Ayarları
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: Colors.blue.shade400,
      scaffoldBackgroundColor: Colors.blue.shade50,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue.shade200,
        foregroundColor: Colors.blueGrey.shade800, // AppBar ikon ve başlık rengi
        elevation: 0,
        centerTitle: true,
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.blue.shade400, // Ana renk (butonlar, vurgular)
        secondary: Colors.lightBlue.shade200, // İkincil renk
        surface: Colors.blue.shade50, // Kart gibi yüzeylerin rengi
        onPrimary: Colors.white, // Ana rengin üzerindeki yazı/ikon rengi
        onSecondary: Colors.blueGrey.shade800, // İkincil rengin üzerindeki yazı/ikon
        tertiary: Colors.blueGrey.shade600,
        onTertiary: Colors.white,
        onSurface: Colors.blueGrey.shade800, //
        primaryContainer: Colors.blue.shade100,
        secondaryContainer: Colors.lightBlue.shade300, // Yüzeylerin üzerindeki yazı/ikon
      ),
      listTileTheme: ListTileThemeData(tileColor: Colors.blue.shade100),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.blueGrey.shade800, // Seçili sekmenin rengi
        unselectedLabelColor: Colors.blueGrey.shade400, // Seçili olmayan sekmenin rengi
        indicatorColor: Colors.blue.shade400, // Altındaki çizginin rengi
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(Colors.blue.shade400),
          textStyle: WidgetStateProperty.all(
            TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.all(Colors.blue.shade100),
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.blue.shade400; // Açıkken topun rengi
          }
          return Colors.blue.shade200; // Kapalıyken topun rengi
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.blue.shade300; // Açıkken yolun rengi
          }
          return Colors.blue.shade100; // Kapalıyken yolun rengi
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.blue.withOpacity(0.05),
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
          borderSide: BorderSide(color: Colors.blue.shade400),
        ),
        labelStyle: TextStyle(color: Colors.blueGrey.shade600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade400, // Butonun arka plan rengi
          foregroundColor: Colors.white, // Buton üzerindeki yazı ve ikon rengi
          elevation: 1, // Butonun gölge yüksekliği
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Köşeleri yuvarlat
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: Colors.blueGrey.shade800, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: Colors.blueGrey.shade700),
        labelLarge: const TextStyle(
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
      primaryColor: Colors.blue.shade700,
      scaffoldBackgroundColor: Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.lightBlue.shade200,
        elevation: 0,
        centerTitle: true,
      ),
      colorScheme: ColorScheme.dark(
        primary: Colors.blue.shade700,
        secondary: Colors.lightBlue.shade800,
        surface: Color(0xFF1E1E1E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.lightBlue.shade100,
        tertiary: Colors.lightBlue.shade300,
        onTertiary: Colors.black,
        primaryContainer: Colors.blue.shade800,
        secondaryContainer: Colors.lightBlue.shade600,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.blue.shade900.withOpacity(0.5),
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
          borderSide: BorderSide(color: Colors.blue.shade700),
        ),
        labelStyle: TextStyle(color: Colors.lightBlue.shade300),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700, // Butonun arka plan rengi
          foregroundColor:
              Colors.white, // Buton üzerindeki yazı ve ikon rengi
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.lightBlue.shade200, // Seçili sekmenin rengi
        unselectedLabelColor: Colors.lightBlue.shade500, // Seçili olmayan sekmenin rengi
        indicatorColor: Colors.blue.shade700, // Altındaki çizginin rengi
      ),
      listTileTheme: ListTileThemeData(tileColor: Colors.blueGrey.shade900),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(Colors.lightBlue.shade300),
          textStyle: WidgetStateProperty.all(
            TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.all(Colors.blue.shade800),
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.blue.shade700; // Açıkken topun rengi
          }
          return Colors.blue.shade900; // Kapalıyken topun rengi
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.blue.shade800; // Açıkken yolun rengi
          }
          return Colors.black; // Kapalıyken yolun rengi
        }),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: Colors.lightBlue.shade200, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: Colors.lightBlue.shade100),
        labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
