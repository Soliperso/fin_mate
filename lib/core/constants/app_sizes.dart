/// iOS HIG-aligned spacing and sizing constants
class AppSizes {
  // ── Base Spacing (8pt grid) ────────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // ── Border Radius ──────────────────────────────────────────────────────────
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 10.0; // iOS default button/input radius
  static const double radiusLg = 14.0; // iOS large card radius
  static const double radiusCard = 16.0; // iOS card / cell group radius
  static const double radiusXl = 20.0; // iOS sheet top radius
  static const double radiusFull = 999.0;

  // ── Icon Sizes ─────────────────────────────────────────────────────────────
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 28.0;
  static const double iconXl = 44.0; // iOS minimum tap target
  static const double iconContainer = 40.0; // icon background container size

  // ── Button Heights ─────────────────────────────────────────────────────────
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 52.0; // standard action button height
  static const double buttonHeightLg = 56.0;

  // ── Elevation / Shadow ─────────────────────────────────────────────────────
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;

  // ── Page Padding ───────────────────────────────────────────────────────────
  static const double pagePadding = 16.0; // iOS standard horizontal inset

  AppSizes._();
}
