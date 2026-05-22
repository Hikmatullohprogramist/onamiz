import 'package:flutter/material.dart';

class AppColors {
  // ── Primary — warm rose ──────────────────────────────────────
  static const primary      = Color(0xFFD86080);
  static const primaryLight = Color(0xFFFDEDF2);
  static const primaryDark  = Color(0xFFB8405E);

  // ── Secondary — soft lavender ────────────────────────────────
  static const secondary      = Color(0xFF9B78CC);
  static const secondaryLight = Color(0xFFF3EEF9);

  // ── Background ───────────────────────────────────────────────
  static const background = Color(0xFFFFF5F8);
  static const surface    = Color(0xFFFFFFFF);
  static const cardBg     = Color(0xFFFFFFFF);

  // ── Status ───────────────────────────────────────────────────
  static const green          = Color(0xFF4CAF7D);
  static const greenLight     = Color(0xFFE8F7EF);
  static const yellow         = Color(0xFFFFB020);
  static const yellowLight    = Color(0xFFFFF8E7);
  static const red            = Color(0xFFE55353);
  static const redLight       = Color(0xFFFFECEC);
  static const emergency      = Color(0xFFC62828);
  static const emergencyLight = Color(0xFFFFD6D6);

  // ── Text ─────────────────────────────────────────────────────
  static const textDark   = Color(0xFF2A1F3D);
  static const textMedium = Color(0xFF5E5077);
  static const textGrey   = Color(0xFF9B93B8);

  // ── UI ───────────────────────────────────────────────────────
  static const divider = Color(0xFFF0E8F0);
  static const border  = Color(0xFFE8DCEE);

  // ── Trimester ────────────────────────────────────────────────
  static const t1Color = Color(0xFF50C8D8);
  static const t2Color = Color(0xFF9B78CC);
  static const t3Color = Color(0xFFF4956A);

  // ── Gradients ────────────────────────────────────────────────
  static const headerGradient = LinearGradient(
    colors: [Color(0xFFE07090), Color(0xFF9B78CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const softPinkGradient = LinearGradient(
    colors: [Color(0xFFFDEDF2), Color(0xFFF3EEF9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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

class AppDecoration {
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.cardBg,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFFD86080).withValues(alpha: 0.07),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration get smallCard => BoxDecoration(
    color: AppColors.cardBg,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFFD86080).withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
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
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: AppColors.cardBg,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 15),
    ),
  );
}
