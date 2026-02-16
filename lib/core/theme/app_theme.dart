import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    // 🎨 الألوان الأساسية
    primaryColor: const Color(0xFF4DA3FF),
    scaffoldBackgroundColor: Colors.white,

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4DA3FF),
      brightness: Brightness.light,
    ),

    // 🧊 تصميم الأزرار
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4DA3FF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 8,
        shadowColor: Colors.blueAccent.withValues(alpha: 0.5),
      ),
    ),

    // 🧊 تصميم البطاقات (الحل هنا 👇)
    cardTheme: CardThemeData(
      elevation: 10,
      shadowColor: Colors.blue.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    fontFamily: 'Roboto',
  );
}
