import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Apple Wallet / Pay inspired theme for FinMate
/// Built on iOS Human Interface Guidelines design tokens
class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.brandTeal,
        secondary: AppColors.brandTeal,
        tertiary: AppColors.systemBlue,
        error: AppColors.systemRed,
        surface: AppColors.systemBackground,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.label,
        surfaceContainerHighest: AppColors.secondarySystemBackground,
        outline: AppColors.separator,
        outlineVariant: AppColors.systemGray4,
        shadow: Colors.black,
      ),
      scaffoldBackgroundColor: AppColors.systemGroupedBackground,
      textTheme: _buildTextTheme(),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: AppColors.systemGroupedBackground,
        foregroundColor: AppColors.label,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.separator,
        iconTheme: IconThemeData(color: AppColors.brandTeal, size: 24),
        actionsIconTheme: IconThemeData(color: AppColors.brandTeal, size: 24),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.label,
          letterSpacing: -0.41,
          fontFamily: '.SF Pro Text',
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusCard)),
        ),
        color: AppColors.systemBackground,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.brandTeal,
          foregroundColor: AppColors.white,
          minimumSize: const Size(0, AppSizes.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandTeal,
          foregroundColor: AppColors.white,
          minimumSize: const Size(0, AppSizes.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandTeal,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.41,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandTeal,
          side: const BorderSide(color: AppColors.brandTeal, width: 1.5),
          minimumSize: const Size(0, AppSizes.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.label, size: 24),
      dividerColor: AppColors.separator,
      dividerTheme: const DividerThemeData(
        color: AppColors.separator,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.systemBackground,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: 2,
        ),
        minLeadingWidth: 0,
        iconColor: AppColors.brandTeal,
        shape: Border(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandTeal;
          }
          return AppColors.systemGray3;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        splashRadius: 14,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandTeal;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.systemGray3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondarySystemBackground,
        suffixIconColor: AppColors.textTertiary,
        prefixIconColor: AppColors.textTertiary,
        hintStyle: const TextStyle(
          color: AppColors.systemGray3,
          fontSize: 17,
          letterSpacing: -0.41,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 17,
          letterSpacing: -0.41,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.separator, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.separator, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.brandTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.systemRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.systemRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        errorStyle: const TextStyle(
          color: AppColors.systemRed,
          fontSize: 13,
          letterSpacing: -0.08,
        ),
      ),
      // iOS-style bottom nav — no indicator pill
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.systemBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.24,
            color: isSelected ? AppColors.brandTeal : AppColors.systemGray,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 26,
            color: isSelected ? AppColors.brandTeal : AppColors.systemGray,
          );
        }),
        height: 83,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.systemBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        elevation: 0,
        dragHandleColor: AppColors.systemGray3,
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.systemBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.label,
          letterSpacing: -0.41,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.secondaryLabel,
          letterSpacing: -0.08,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandTeal,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.systemGray5,
        selectedColor: AppColors.brandTeal.withValues(alpha: 0.15),
        labelStyle: const TextStyle(
          fontSize: 13,
          letterSpacing: -0.08,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        side: BorderSide.none,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.brandTealLight,
        secondary: AppColors.brandTealLight,
        tertiary: AppColors.systemBlue,
        error: AppColors.systemRed,
        surface: AppColors.secondarySystemBackgroundDark,
        onPrimary: AppColors.systemBackgroundDark,
        onSecondary: AppColors.white,
        onSurface: AppColors.labelDark,
        surfaceContainerHighest: AppColors.tertiarySystemBackgroundDark,
        outline: AppColors.separatorDark,
        outlineVariant: AppColors.separatorDark,
      ),
      scaffoldBackgroundColor: AppColors.systemGroupedBackgroundDark,
      textTheme: _buildTextTheme(isDark: true),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: AppColors.systemGroupedBackgroundDark,
        foregroundColor: AppColors.labelDark,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.separatorDark,
        iconTheme: IconThemeData(color: AppColors.brandTealLight, size: 24),
        actionsIconTheme: IconThemeData(color: AppColors.brandTealLight, size: 24),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.labelDark,
          letterSpacing: -0.41,
          fontFamily: '.SF Pro Text',
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusCard)),
        ),
        color: AppColors.secondarySystemBackgroundDark,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.brandTealLight,
          foregroundColor: AppColors.systemBackgroundDark,
          minimumSize: const Size(0, AppSizes.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandTealLight,
          foregroundColor: AppColors.systemBackgroundDark,
          minimumSize: const Size(0, AppSizes.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandTealLight,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.41,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.labelDark, size: 24),
      dividerColor: AppColors.separatorDark,
      dividerTheme: const DividerThemeData(
        color: AppColors.separatorDark,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.secondarySystemBackgroundDark,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: 2,
        ),
        minLeadingWidth: 0,
        iconColor: AppColors.brandTealLight,
        shape: Border(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandTeal;
          }
          return AppColors.tertiarySystemBackgroundDark;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        splashRadius: 14,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandTealLight;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.systemGray),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF141414),
        suffixIconColor: AppColors.tertiaryLabelDark,
        prefixIconColor: AppColors.tertiaryLabelDark,
        hintStyle: TextStyle(
          color: AppColors.white.withValues(alpha: 0.25),
          fontSize: 17,
          letterSpacing: -0.41,
        ),
        labelStyle: TextStyle(
          color: AppColors.white.withValues(alpha: 0.35),
          fontSize: 17,
          letterSpacing: -0.41,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.separatorDark, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.separatorDark, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.brandTealLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.systemRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.systemRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        errorStyle: const TextStyle(
          color: AppColors.systemRed,
          fontSize: 13,
          letterSpacing: -0.08,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.secondarySystemBackgroundDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.24,
            color: isSelected ? AppColors.brandTealLight : AppColors.systemGray,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 26,
            color: isSelected ? AppColors.brandTealLight : AppColors.systemGray,
          );
        }),
        height: 83,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandTealLight,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.secondarySystemBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        elevation: 0,
        dragHandleColor: AppColors.systemGray,
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.secondarySystemBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.labelDark,
          letterSpacing: -0.41,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.secondaryLabelDark,
          letterSpacing: -0.08,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandTealLight,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.tertiarySystemBackgroundDark,
        selectedColor: AppColors.brandTealLight.withValues(alpha: 0.2),
        labelStyle: const TextStyle(
          fontSize: 13,
          letterSpacing: -0.08,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        side: BorderSide.none,
      ),
    );
  }

  // iOS HIG typography scale
  static TextTheme _buildTextTheme({bool isDark = false}) {
    final baseColor = isDark ? AppColors.labelDark : AppColors.label;
    final secondaryColor = isDark ? AppColors.secondaryLabelDark : AppColors.secondaryLabel;

    return TextTheme(
      // Large Title — 34pt Regular
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: 0.37,
      ),
      // Title 1 — 28pt Regular
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: 0.36,
      ),
      // Title 2 — 22pt Regular
      displaySmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: 0.35,
      ),
      // Title 3 — 20pt Regular
      headlineLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: 0.38,
      ),
      // Headline — 17pt Semibold
      headlineMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.41,
      ),
      // Used for section headers
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.38,
      ),
      // Headline — 17pt Semibold
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.41,
      ),
      // Subheadline — 15pt Regular
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: baseColor,
        letterSpacing: -0.24,
      ),
      // Caption 1 — 12pt Regular
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: baseColor,
        letterSpacing: -0.08,
      ),
      // Body — 17pt Regular
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: -0.41,
      ),
      // Callout — 16pt Regular
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: -0.32,
      ),
      // Footnote — 13pt Regular
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        letterSpacing: -0.08,
      ),
      // Label — 17pt Semibold
      labelLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.41,
      ),
      // Caption 2 — 11pt Regular
      labelMedium: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.06,
      ),
      // Caption 2 compact
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.12,
      ),
    );
  }

  AppTheme._();
}
