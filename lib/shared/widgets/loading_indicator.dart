import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Compact, consistently-styled loading spinner for button and form submission states.
/// Use this instead of bare CircularProgressIndicator(strokeWidth: 2) throughout the app.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 20.0, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? AppColors.brandTeal,
      ),
    );
  }
}
