/// Visual effects constants for the app
///
/// This file contains constants for glassmorphism and other visual effects
/// used throughout the FinMate application.
class AppEffects {
  // Glassmorphism Blur Values
  /// Subtle blur for minimal frosted glass effect
  static const double blurSm = 10.0;

  /// Medium blur for standard glassmorphic elements
  static const double blurMd = 15.0;

  /// Large blur for prominent glassmorphic overlays
  static const double blurLg = 20.0;

  // Glassmorphism Opacity Values
  /// High opacity for text-heavy content (maintains readability)
  static const double opacityHigh = 0.95;

  /// Medium-high opacity for modal overlays
  static const double opacityMediumHigh = 0.9;

  /// Medium opacity for subtle glassmorphic elements
  static const double opacityMedium = 0.85;

  /// Lower opacity for decorative glassmorphic backgrounds
  static const double opacityLow = 0.8;

  // Border Opacity for Glass Elements
  /// Light border opacity for glassmorphic containers in light mode
  static const double borderOpacityLight = 0.4;

  /// Light border opacity for glassmorphic containers in dark mode
  static const double borderOpacityDark = 0.2;

  AppEffects._();
}
