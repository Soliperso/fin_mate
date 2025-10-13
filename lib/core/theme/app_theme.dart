import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryTeal,
        secondary: AppColors.slateBlue,
        tertiary: AppColors.tealBlue,
        error: AppColors.error,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.lightGray,
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: AppSizes.elevationSm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusMd)),
        ),
        color: AppColors.cardBackground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, AppSizes.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryTeal,
        secondary: AppColors.slateBlue,
        tertiary: AppColors.tealBlue,
        error: AppColors.error,
        surface: AppColors.cardBackgroundDark,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: _buildTextTheme(isDark: true),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.cardBackgroundDark,
        foregroundColor: AppColors.white,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: AppSizes.elevationSm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusMd)),
        ),
        color: AppColors.cardBackgroundDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, AppSizes.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme({bool isDark = false}) {
    final baseColor = isDark ? AppColors.white : AppColors.textPrimary;
    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: baseColor,
        ),
        displayMedium: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: baseColor,
        ),
        displaySmall: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: baseColor,
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: baseColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: baseColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: baseColor,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: baseColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: baseColor,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: baseColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: baseColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: baseColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: isDark ? AppColors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: baseColor,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: baseColor,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
        ),
      ),
    );
  }

  AppTheme._();
}
