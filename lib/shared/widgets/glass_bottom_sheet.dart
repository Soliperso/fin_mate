import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_effects.dart';

/// A glassmorphic bottom sheet wrapper
///
/// Provides a frosted glass effect for modal bottom sheets while maintaining
/// high readability for content. Uses high opacity (85-90%) to ensure text
/// contrast meets accessibility standards.
class GlassBottomSheet {
  /// Shows a glassmorphic modal bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double blur = AppEffects.blurMd,
    double opacity = AppEffects.opacityMediumHigh,
    bool enableGlass = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBackgroundColor = isDark
        ? AppColors.cardBackgroundDark.withValues(alpha: opacity)
        : AppColors.white.withValues(alpha: opacity);

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        if (!enableGlass) {
          // Fallback to solid background
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardBackgroundDark : AppColors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusLg),
              ),
            ),
            child: child,
          );
        }

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? defaultBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusLg),
                ),
                border: Border.all(
                  color: isDark
                      ? AppColors.white.withValues(alpha: AppEffects.borderOpacityDark / 2)
                      : AppColors.white.withValues(alpha: AppEffects.borderOpacityLight * 0.75),
                  width: 1,
                ),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Shows a glassmorphic draggable scrollable bottom sheet
  static Future<T?> showDraggable<T>({
    required BuildContext context,
    required Widget Function(BuildContext, ScrollController) builder,
    bool isDismissible = true,
    bool enableDrag = true,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.95,
    Color? backgroundColor,
    double blur = AppEffects.blurMd,
    double opacity = AppEffects.opacityMediumHigh,
    bool enableGlass = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBackgroundColor = isDark
        ? AppColors.cardBackgroundDark.withValues(alpha: opacity)
        : AppColors.white.withValues(alpha: opacity);

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        Widget sheetContent = DraggableScrollableSheet(
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          expand: false,
          builder: (context, scrollController) {
            return builder(context, scrollController);
          },
        );

        if (!enableGlass) {
          // Fallback to solid background
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardBackgroundDark : AppColors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusLg),
              ),
            ),
            child: sheetContent,
          );
        }

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? defaultBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusLg),
                ),
                border: Border.all(
                  color: isDark
                      ? AppColors.white.withValues(alpha: AppEffects.borderOpacityDark / 2)
                      : AppColors.white.withValues(alpha: AppEffects.borderOpacityLight * 0.75),
                  width: 1,
                ),
              ),
              child: sheetContent,
            ),
          ),
        );
      },
    );
  }
}
