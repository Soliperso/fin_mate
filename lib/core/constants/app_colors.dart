import 'package:flutter/material.dart';

/// FinMate color system — Apple Wallet / Pay inspired
/// Built on iOS system semantic colors for authentic iOS feel
class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const brandTeal = Color(0xFF20808D);
  static const brandTealLight = Color(0xFF2D9DA9);

  // Kept for legacy references in older widgets
  static const primaryTeal = brandTeal;
  static const tealLight = brandTealLight;
  static const tealDark = Color(0xFF176673);
  static const splashTeal = Color(0xFF143F48);
  static const iconTeal = Color(0xFF156570);
  static const deepNavy = Color(0xFF1A2B4C);
  static const slateBlue = Color(0xFF2C5F8D);
  static const tealBlue = Color(0xFF30B0C7);

  // ── iOS System Accent Colors ───────────────────────────────────────────────
  static const systemBlue = Color(0xFF007AFF);
  static const systemGreen = Color(0xFF34C759);
  static const systemRed = Color(0xFFFF3B30);
  static const systemOrange = Color(0xFFFF9500);
  static const systemYellow = Color(0xFFFFCC00);
  static const systemPurple = Color(0xFFAF52DE);
  static const systemPink = Color(0xFFFF2D55);
  static const systemIndigo = Color(0xFF5856D6);
  static const systemTeal = Color(0xFF30B0C7);
  static const systemMint = Color(0xFF00C7BE);
  static const systemCyan = Color(0xFF32ADE6);

  // ── iOS Gray Scale ─────────────────────────────────────────────────────────
  static const systemGray = Color(0xFF8E8E93);
  static const systemGray2 = Color(0xFFAEAEB2);
  static const systemGray3 = Color(0xFFC7C7CC);
  static const systemGray4 = Color(0xFFD1D1D6);
  static const systemGray5 = Color(0xFFE5E5EA);
  static const systemGray6 = Color(0xFFF2F2F7);

  // ── System Backgrounds — Light ─────────────────────────────────────────────
  static const systemBackground = Color(0xFFFFFFFF);
  static const secondarySystemBackground = Color(0xFFF2F2F7);
  static const tertiarySystemBackground = Color(0xFFFFFFFF);
  static const systemGroupedBackground = Color(0xFFF2F2F7);
  static const secondarySystemGroupedBackground = Color(0xFFFFFFFF);
  static const tertiarySystemGroupedBackground = Color(0xFFF2F2F7);

  // ── System Backgrounds — Dark ──────────────────────────────────────────────
  static const systemBackgroundDark = Color(0xFF000000);
  static const secondarySystemBackgroundDark = Color(0xFF1C1C1E);
  static const tertiarySystemBackgroundDark = Color(0xFF2C2C2E);
  static const systemGroupedBackgroundDark = Color(0xFF000000);
  static const secondarySystemGroupedBackgroundDark = Color(0xFF1C1C1E);
  static const tertiarySystemGroupedBackgroundDark = Color(0xFF3A3A3C);

  // ── Labels — Light ─────────────────────────────────────────────────────────
  // Using opaque equivalents so they render correctly on any Flutter background
  static const label = Color(0xFF000000);
  static const secondaryLabel = Color(0xFF6C6C72); // iOS secondary label (opaque)
  static const tertiaryLabel = Color(0xFFAEAEB2);  // iOS tertiary label (opaque)
  static const quaternaryLabel = Color(0xFFC7C7CC);

  // ── Labels — Dark ──────────────────────────────────────────────────────────
  static const labelDark = Color(0xFFFFFFFF);
  static const secondaryLabelDark = Color(0xFF8E8E93); // iOS system gray
  static const tertiaryLabelDark = Color(0xFF636366);

  // ── Separators ─────────────────────────────────────────────────────────────
  static const separator = Color(0xFFC6C6C8);
  static const separatorDark = Color(0xFF38383A);
  static const opaqueSeparator = Color(0xFFC6C6C8);

  // ── Semantic aliases (used throughout the app) ─────────────────────────────
  static const white = Color(0xFFFFFFFF);
  static const charcoal = Color(0xFF000000);

  // Text
  static const textPrimary = label;
  static const textSecondary = secondaryLabel;
  static const textTertiary = tertiaryLabel;

  // Status
  static const success = systemGreen;
  static const warning = systemOrange;
  static const error = systemRed;
  static const info = systemBlue;

  // Background (legacy)
  static const lightGray = systemGray6;
  static const backgroundLight = systemBackground;
  static const backgroundDark = systemBackgroundDark;
  static const cardBackground = systemBackground;
  static const cardBackgroundDark = secondarySystemBackgroundDark;

  // Borders (legacy)
  static const borderLight = separator;
  static const borderMedium = systemGray4;
  static const borderDark = separatorDark;

  // Gradients for hero cards
  static const gradientStart = brandTeal;
  static const gradientEnd = brandTealLight;
  static const brandTealDark = Color(0xFF1A6B76);   // net worth positive gradient end
  static const systemRedDeep = Color(0xFFB52D23);   // net worth negative gradient end
  static const debtRedStart = Color(0xFFCC2B2B);    // debt hero gradient start
  static const debtRedEnd = Color(0xFF8B1A1A);      // debt hero gradient end

  // Shadow helper — avoids duplicating the isDark check in every card widget
  static List<BoxShadow> cardShadow(bool isDark) => isDark
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ];

  AppColors._();
}
