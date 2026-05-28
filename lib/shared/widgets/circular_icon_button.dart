import 'package:flutter/material.dart';

/// A circular icon button with a card-colored background.
/// Used for back (chevron_left) and close (xmark) navigation buttons.
class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;

  const CircularIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 36,
    this.iconSize = 18,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Theme.of(context).cardTheme.color,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor ?? Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }
}
