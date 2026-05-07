import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

const _chipIcons = [
  CupertinoIcons.chart_bar_alt_fill,
  CupertinoIcons.calendar,
  CupertinoIcons.creditcard,
  CupertinoIcons.lightbulb,
  CupertinoIcons.tag,
];

class SuggestedPrompts extends StatelessWidget {
  final List<String> prompts;
  final Function(String) onPromptTap;

  const SuggestedPrompts({
    super.key,
    required this.prompts,
    required this.onPromptTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.md,
            bottom: AppSizes.xs + 2,
          ),
          child: Text(
            'Quick questions',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Row(
            children: prompts.asMap().entries.map((entry) {
              final icon = _chipIcons[entry.key % _chipIcons.length];
              return Padding(
                padding: const EdgeInsets.only(right: AppSizes.sm),
                child: _PromptChip(
                  prompt: entry.value,
                  icon: icon,
                  onTap: () => onPromptTap(entry.value),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String prompt;
  final IconData icon;
  final VoidCallback onTap;

  const _PromptChip({
    required this.prompt,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.brandTeal.withValues(
              alpha: isDark ? 0.12 : 0.06,
            ),
            border: Border.all(
              color: AppColors.brandTeal.withValues(
                alpha: isDark ? 0.4 : 0.25,
              ),
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.brandTeal),
              const SizedBox(width: AppSizes.xs),
              Text(
                prompt,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
