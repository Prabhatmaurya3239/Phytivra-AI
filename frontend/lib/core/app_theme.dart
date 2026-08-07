import 'package:flutter/material.dart';

class AppTheme {
  // Centralized Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.green, // Common Color Palette
      primaryColor: Colors.green.shade700,
      scaffoldBackgroundColor: Colors.grey.shade50,
      fontFamily: 'Roboto', // Consistent Typography
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      
      // Button Styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      
      // Secondary Button Styles
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green.shade700,
          side: BorderSide(color: Colors.green.shade700, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      
      // Card Styles[cite: 2]
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      
      // Input Field Styles[cite: 2]
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}