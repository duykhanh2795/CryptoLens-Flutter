import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF050607);
  static const surface = Color(0xFF111112);
  static const surfaceVariant = Color(0xFF1B1C1E);
  static const surfaceElevated = Color(0xFF171719);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFFA7ABB0);
  static const textTertiary = Color(0xFF6E737A);
  static const divider = Color(0xFF222326);
  static const border = Color(0xFF303136);
  static const accent = Color(0xFFE8ECEF);
  static const accentContainer = Color(0xFF25272B);
  static const green = Color(0xFF00C087);
  static const red = Color(0xFFFF7182);
  static const greenSurface = Color(0xFF0F2A22);
  static const redSurface = Color(0xFF28161B);
  static const aiPurple = Color(0xFF8F7BE5);
  static const aiPurpleSurface = Color(0xFF292338);
}

class CryptoLensTheme {
  static ThemeData get lightTheme {
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.background,
      primaryContainer: AppColors.accentContainer,
      secondary: AppColors.green,
      tertiary: AppColors.red,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurface: AppColors.textPrimary,
      outline: Colors.transparent,
      error: AppColors.red,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      textTheme:
          const TextTheme(
            headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            headlineMedium: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
            titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ).apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 78,
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.accentContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
    );
  }
}
