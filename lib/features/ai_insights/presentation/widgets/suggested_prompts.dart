import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Text(
            'Suggestions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Row(
            children: prompts.map((prompt) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSizes.sm),
                child: _PromptChip(
                  prompt: prompt,
                  onTap: () => onPromptTap(prompt),
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
  final VoidCallback onTap;

  const _PromptChip({
    required this.prompt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightGray,
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
            border: Border.all(
              color: AppColors.borderLight,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: AppColors.primaryTeal,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                prompt,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
