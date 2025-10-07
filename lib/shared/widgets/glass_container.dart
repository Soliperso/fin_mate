import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_effects.dart';

/// A glassmorphic container with frosted glass effect
///
/// This widget provides a customizable glassmorphism effect suitable for
/// non-critical UI elements. It maintains accessibility by providing high
/// opacity backgrounds and proper contrast ratios.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool enableGlass;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = AppEffects.blurSm,
    this.opacity = AppEffects.opacityMedium,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.enableGlass = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.cardBackgroundDark.withValues(alpha: opacity)
        : AppColors.white.withValues(alpha: opacity);

    // Fallback to solid background if glass is disabled (for accessibility)
    if (!enableGlass) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : AppColors.white,
          borderRadius: borderRadius,
          border: border,
        ),
        child: child,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              border: border ?? Border.all(
                color: isDark
                    ? AppColors.white.withValues(alpha: AppEffects.borderOpacityDark)
                    : AppColors.white.withValues(alpha: AppEffects.borderOpacityLight),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
