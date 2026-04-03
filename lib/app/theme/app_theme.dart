import 'package:flutter/material.dart';

import 'app_metrics.dart';

class AppPalette {
  static const canvas = Color(0xFFF2F6FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFE8F0FF);
  static const text = Color(0xFF21304F);
  static const muted = Color(0xFF6E7B97);
  static const patientPrimary = Color(0xFF1E88E5);
  static const patientAccent = Color(0xFF5BC7FF);
  static const pharmacistPrimary = Color(0xFF0F766E);
  static const pharmacistAccent = Color(0xFF55D8B4);
  static const adminPrimary = Color(0xFF5B5FE8);
  static const coral = Color(0xFFFF7E79);
  static const amber = Color(0xFFFFC857);
  static const success = Color(0xFF2BB673);
}

class AppTheme {
  static ThemeData lightTheme() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppPalette.patientPrimary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppPalette.patientPrimary,
          secondary: AppPalette.patientAccent,
          surface: AppPalette.surface,
          onSurface: AppPalette.text,
          onSurfaceVariant: AppPalette.muted,
          outlineVariant: const Color(0xFFD5E0F3),
          error: const Color(0xFFD94B63),
        );

    const textTheme = TextTheme(
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
      headlineMedium: TextStyle(
        fontSize: AppFontSize.hero,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(
        fontSize: AppFontSize.pageTitle,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      titleLarge: TextStyle(
        fontSize: AppFontSize.sectionTitle,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        fontSize: AppFontSize.title,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: AppFontSize.bodyLarge, height: 1.5),
      bodyMedium: TextStyle(fontSize: AppFontSize.body, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, height: 1.45),
      labelLarge: TextStyle(
        fontSize: AppFontSize.body,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(
        fontSize: AppFontSize.caption,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.canvas,
      fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Arial'],
      textTheme: textTheme.apply(
        bodyColor: AppPalette.text,
        displayColor: AppPalette.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppPalette.text,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: const Color(0xFFDDE6F6),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            color: isSelected ? AppPalette.patientPrimary : AppPalette.muted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: AppFontSize.caption,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? AppPalette.patientPrimary : AppPalette.muted,
          );
        }),
        indicatorColor: AppPalette.patientPrimary.withValues(alpha: 0.12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.surfaceAlt,
        selectedColor: AppPalette.patientPrimary.withValues(alpha: 0.14),
        disabledColor: const Color(0xFFF1F4FB),
        labelStyle: const TextStyle(
          color: AppPalette.text,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        hintStyle: const TextStyle(
          color: AppPalette.muted,
          fontSize: AppFontSize.body,
        ),
        labelStyle: const TextStyle(
          color: AppPalette.muted,
          fontSize: AppFontSize.body,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
            color: AppPalette.patientPrimary.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: AppPalette.patientPrimary,
            width: 1.5,
          ),
        ),
        prefixIconColor: AppPalette.muted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor: AppPalette.patientPrimary,
          foregroundColor: Colors.white,
          shadowColor: AppPalette.patientPrimary.withValues(alpha: 0.35),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: const TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(42),
          foregroundColor: AppPalette.text,
          side: BorderSide(
            color: AppPalette.patientPrimary.withValues(alpha: 0.14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: const TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.text,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: AppFontSize.body,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
