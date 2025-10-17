import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class MessageActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const MessageActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.primaryTeal.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: textColor ?? AppColors.primaryTeal,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor ?? AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageActionButtons extends StatelessWidget {
  final List<Map<String, dynamic>> actions;

  const MessageActionButtons({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: actions.map((action) {
        return MessageActionButton(
          label: action['label'] as String,
          icon: action['icon'] as IconData,
          onTap: action['onTap'] as VoidCallback,
          backgroundColor: action['backgroundColor'] as Color?,
          textColor: action['textColor'] as Color?,
        );
      }).toList(),
    );
  }
}
