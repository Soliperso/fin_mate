import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

enum PasswordStrength { weak, medium, strong, veryStrong }

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    required this.password,
    super.key,
  });

  PasswordStrength _calculateStrength() {
    if (password.isEmpty) return PasswordStrength.weak;

    int score = 0;

    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Complexity checks
    if (RegExp(r'[A-Z]').hasMatch(password)) score++; // Has uppercase
    if (RegExp(r'[a-z]').hasMatch(password)) score++; // Has lowercase
    if (RegExp(r'[0-9]').hasMatch(password)) score++; // Has number
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++; // Has special char

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 5) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  Color _getStrengthColor() {
    switch (_calculateStrength()) {
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.medium:
        return AppColors.warning;
      case PasswordStrength.strong:
        return AppColors.success;
      case PasswordStrength.veryStrong:
        return AppColors.primaryTeal;
    }
  }

  String _getStrengthText() {
    switch (_calculateStrength()) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  double _getStrengthProgress() {
    switch (_calculateStrength()) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.medium:
        return 0.5;
      case PasswordStrength.strong:
        return 0.75;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = _calculateStrength();
    final color = _getStrengthColor();
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    final hasMinLength = password.length >= 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.xs),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  tween: Tween(begin: 0, end: _getStrengthProgress()),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              _getStrengthText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.xs,
          children: [
            _RequirementChip(
              label: '8+ characters',
              isMet: hasMinLength,
            ),
            _RequirementChip(
              label: 'Uppercase',
              isMet: hasUppercase,
            ),
            _RequirementChip(
              label: 'Lowercase',
              isMet: hasLowercase,
            ),
            _RequirementChip(
              label: 'Number',
              isMet: hasNumber,
            ),
            _RequirementChip(
              label: 'Special char',
              isMet: hasSpecialChar,
            ),
          ],
        ),
      ],
    );
  }
}

class _RequirementChip extends StatelessWidget {
  final String label;
  final bool isMet;

  const _RequirementChip({
    required this.label,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs / 2,
      ),
      decoration: BoxDecoration(
        color: isMet
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.textTertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.xs),
        border: Border.all(
          color: isMet
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.textTertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 12,
            color: isMet ? AppColors.success : AppColors.textTertiary,
          ),
          const SizedBox(width: AppSizes.xs / 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: isMet ? AppColors.success : AppColors.textSecondary,
                  fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}
