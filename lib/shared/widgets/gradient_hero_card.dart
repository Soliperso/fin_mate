import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';

/// Reusable gradient container shell shared by all hero summary cards
/// (NetWorthCard, DebtHeroCard, BudgetHeroCard, GoalsSummaryCard).
///
/// Encapsulates the repeated pattern: full-width container, topLeft→bottomRight
/// LinearGradient, rounded corners, drop shadow, and uniform padding.
class GradientHeroCard extends StatelessWidget {
  final List<Color> gradientColors;

  /// Pre-built shadow color — include the desired opacity via [Color.withValues].
  final Color shadowColor;

  final Widget child;

  /// Defaults match the standard hero card shadow (blur 20, offset (0,8)).
  final double shadowBlurRadius;
  final Offset shadowOffset;

  const GradientHeroCard({
    super.key,
    required this.gradientColors,
    required this.shadowColor,
    required this.child,
    this.shadowBlurRadius = 20,
    this.shadowOffset = const Offset(0, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: shadowBlurRadius,
            offset: shadowOffset,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: child,
    );
  }
}
