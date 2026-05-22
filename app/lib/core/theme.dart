import 'package:flutter/material.dart';

class AppColors {
  static const primary       = Color(0xFFE91E8C);
  static const primaryLight  = Color(0xFFFCE4EC);
  static const primaryDark   = Color(0xFFC2185B);
  static const secondary     = Color(0xFF9C27B0);
  static const accent        = Color(0xFFFF6B9D);
  static const background    = Color(0xFFF8F9FF);
  static const surface       = Colors.white;
  static const cardBg        = Color(0xFFFFFFFF);

  static const green         = Color(0xFF2ECC71);
  static const greenLight    = Color(0xFFEAFAF1);
  static const yellow        = Color(0xFFF39C12);
  static const yellowLight   = Color(0xFFFEF9E7);
  static const red           = Color(0xFFE74C3C);
  static const redLight      = Color(0xFFFDEDEC);
  static const emergency     = Color(0xFFC0392B);
  static const emergencyLight= Color(0xFFFFCDD2);

  static const textDark      = Color(0xFF1A1A2E);
  static const textMedium    = Color(0xFF4A4A6A);
  static const textGrey      = Color(0xFF9B9BB4);
  static const divider       = Color(0xFFEEEEF5);

  static const t1Color       = Color(0xFF4ECDC4);
  static const t2Color       = Color(0xFFE91E8C);
  static const t3Color       = Color(0xFF9C27B0);

  static Color riskColor(String risk) => switch (risk) {
    'yashil'     => green,
    'sariq'      => yellow,
    'qizil'      => red,
    'favqulodda' => emergency,
    _            => green,
  };

  static Color riskLightColor(String risk) => switch (risk) {
    'yashil'     => greenLight,
    'sariq'      => yellowLight,
    'qizil'      => redLight,
    'favqulodda' => emergencyLight,
    _            => greenLight,
  };
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: 'SF Pro Display',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textDark,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: AppColors.cardBg,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
          color: AppColors.textDark, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
          color: AppColors.textDark, letterSpacing: -0.3),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
          color: AppColors.textDark, letterSpacing: -0.2),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
          color: AppColors.textDark),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textMedium, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.4),
    ),
  );
}
