import 'package:flutter/material.dart';

class AppColors {
  // Asosiy ranglar
  static const primary    = Color(0xFFE91E8C);
  static const primaryLight = Color(0xFFFCE4EC);
  static const secondary  = Color(0xFF9C27B0);
  static const background = Color(0xFFFAFAFA);
  static const surface    = Colors.white;

  // Xavf darajalari
  static const green      = Color(0xFF4CAF50);
  static const greenLight = Color(0xFFE8F5E9);
  static const yellow     = Color(0xFFFFA500);
  static const yellowLight = Color(0xFFFFF8E1);
  static const red        = Color(0xFFFF4444);
  static const redLight   = Color(0xFFFFEBEE);
  static const emergency  = Color(0xFFD32F2F);
  static const emergencyLight = Color(0xFFFFCDD2);

  // Matn
  static const textDark   = Color(0xFF212121);
  static const textGrey   = Color(0xFF757575);
  static const textLight  = Color(0xFFBDBDBD);

  static Color riskColor(String risk) {
    switch (risk) {
      case 'yashil':     return green;
      case 'sariq':      return yellow;
      case 'qizil':      return red;
      case 'favqulodda': return emergency;
      default:           return green;
    }
  }

  static Color riskLightColor(String risk) {
    switch (risk) {
      case 'yashil':     return greenLight;
      case 'sariq':      return yellowLight;
      case 'qizil':      return redLight;
      case 'favqulodda': return emergencyLight;
      default:           return greenLight;
    }
  }
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark,
      ),
      headlineMedium: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark,
      ),
      titleLarge: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark,
      ),
      titleMedium: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16, color: AppColors.textDark,
      ),
      bodyMedium: TextStyle(
        fontSize: 14, color: AppColors.textGrey,
      ),
    ),
  );
}
