import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Reusable stat badge used inside gradient hero cards.
/// Displays a [label] above a bold [value] in a semi-transparent pill.
/// Set [highlight] to true to tint the background red (e.g. "at risk" state).
class HeroStatBadge extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const HeroStatBadge({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs + 2,
        ),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFFB52D23)
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
