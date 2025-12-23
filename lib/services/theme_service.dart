import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF1E3A8A),
    scaffoldBackgroundColor: Colors.white,
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E3A8A),
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Color(0xFF1E3A8A),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      titleMedium:
          TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.black54),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
      ),
      fillColor: Colors.white,
      filled: true,
    ),
    dividerColor: Colors.grey.shade300,
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 1,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF3B82F6),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFF1A1F36),
      surfaceTintColor: Color(0xFF1A1F36),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F2937),
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Color(0xFF1F2937),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1F36),
      elevation: 2,
      surfaceTintColor: const Color(0xFF1A1F36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge:
          TextStyle(color: Color(0xFFE5E7EB), fontWeight: FontWeight.bold),
      titleMedium:
          TextStyle(color: Color(0xFFE5E7EB), fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Color(0xFFE5E7EB)),
      bodyMedium: TextStyle(color: Color(0xFFD1D5DB)),
      bodySmall: TextStyle(color: Color(0xFF9CA3AF)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 2),
      ),
      fillColor: const Color(0xFF111827),
      filled: true,
    ),
    dividerColor: Colors.grey.shade700,
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade700,
      thickness: 1,
    ),
  );
}
