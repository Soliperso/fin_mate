import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Shared section header used throughout the app.
/// Shows a [title] on the left and an optional tappable [actionLabel] on the right.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
      ],
    );
  }
}
