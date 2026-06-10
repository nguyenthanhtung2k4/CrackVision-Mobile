import 'package:flutter/material.dart';

// ── Đại Nam University Palette (từ Figma) ──────────────────
// Primary orange  : #E8751A
// Dark orange     : #8B2E00
// Mid orange      : #C4561A
// Light bg        : #FFF8F2
// Cream           : #FFF5EC / #FFF0E0
// Border          : #FFE0C8
// Positive (crack): #EF4444
// Negative (clean): #22C55E
// Warning         : #FFB347
// Text dark       : #3D1A00
// Text mid        : #6B3A1F
// Text muted      : #9CA3AF

class AppColors {
  // Primary
  static const primary = Color(0xFFE8751A);
  static const primaryDark = Color(0xFF8B2E00);
  static const primaryMid = Color(0xFFC4561A);

  // Background
  static const background = Color(0xFFFFF8F2);
  static const backgroundLight = Color(0xFFFFF5EC);
  static const backgroundCream = Color(0xFFFFF0E0);
  static const surface = Color(0xFFFFFFFF);

  // Border
  static const border = Color(0xFFFFE0C8);
  static const borderLight = Color(0xFFFFCF9E);

  // Text
  static const textDark = Color(0xFF3D1A00);
  static const textMid = Color(0xFF6B3A1F);
  static const textMuted = Color(0xFF9CA3AF);

  // Status
  static const crackPositive = Color(0xFFEF4444);   // Có vết nứt
  static const crackNegative = Color(0xFF22C55E);   // Không có vết nứt
  static const crackWarning = Color(0xFFFFB347);    // Vết nứt nhỏ

  // Dark mode
  static const backgroundDark = Color(0xFF1A1A1A);
  static const surfaceDark = Color(0xFF2A2A2A);
  static const textDarkMode = Color(0xFFF5F5F5);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8751A), Color(0xFFC4561A), Color(0xFF8B2E00)],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient darkButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B2E00), Color(0xFF5C1900)],
  );

  static const LinearGradient outerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD4A8), Color(0xFFFFBF80), Color(0xFFFFA55A), Color(0xFFFF8C35)],
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      surface: AppColors.surface,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textDark,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F3F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primary,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textDarkMode,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardColor: AppColors.surfaceDark,
    dividerColor: const Color(0xFF3A3A3A),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2A2A2A),
      foregroundColor: AppColors.textDarkMode,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textDarkMode,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF333333),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textDarkMode),
      bodyMedium: TextStyle(color: AppColors.textDarkMode),
      bodySmall: TextStyle(color: Color(0xFFD1D5DB)),
      titleLarge: TextStyle(color: AppColors.textDarkMode, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: AppColors.textDarkMode, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: Color(0xFFD1D5DB)),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF2A2A2A),
      titleTextStyle: TextStyle(color: AppColors.textDarkMode, fontSize: 16, fontWeight: FontWeight.w700),
      contentTextStyle: TextStyle(color: Color(0xFF9CA3AF)),
    ),
  );
}
