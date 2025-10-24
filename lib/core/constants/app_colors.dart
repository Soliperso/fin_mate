import 'package:flutter/material.dart';

/// FinMate color system - Professional fintech palette
/// Inspired by Perplexity's clean, modern teal aesthetic
class AppColors {
  // Primary Colors - Teal/Turquoise Theme
  static const deepNavy = Color(0xFF1A2B4C);
  static const primaryTeal = Color(0xFF20808D); // Perplexity's turquoise
  static const tealLight = Color(0xFF2D9DA9); // Lighter teal accent
  static const tealDark = Color(0xFF176673); // Darker teal for depth
  static const splashTeal = Color(0xFF143F48); // Icon background teal

  // Secondary Colors
  static const slateBlue = Color(0xFF2C5F8D); // Professional slate blue
  static const tealBlue = Color(0xFF00CEC9); // Vibrant teal accent

  // Neutral Colors
  static const lightGray = Color(0xFFF5F7FA);
  static const white = Color(0xFFFFFFFF);
  static const charcoal = Color(0xFF2D3436);

  // Status Colors
  static const success = Color(0xFF20808D); // Using teal for success
  static const warning = Color(0xFFF39C12);
  static const error = Color(0xFFE74C3C);
  static const info = Color(0xFF3498DB);

  // Gradient Colors
  static const gradientStart = primaryTeal;
  static const gradientEnd = tealBlue;

  // Legacy alias for backward compatibility (deprecated)
  @Deprecated('Use primaryTeal instead')
  static const emeraldGreen = primaryTeal;

  // Text Colors
  static const textPrimary = charcoal;
  static const textSecondary = Color(0xFF636E72);
  static const textTertiary = Color(0xFF95A5A6);

  // Background Colors
  static const backgroundLight = white;
  static const backgroundDark = Color(0xFF0F1419);
  static const cardBackground = white;
  static const cardBackgroundDark = Color(0xFF1E2731);

  // Border Colors
  static const borderLight = Color(0xFFE1E8ED);
  static const borderDark = Color(0xFF2D3748);

  AppColors._();
}
