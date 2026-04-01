import 'package:flutter/material.dart';

/// A circular icon button with a card-colored background.
/// Used for back (chevron_left) and close (xmark) navigation buttons.
class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const CircularIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 36,
    this.iconSize = 18,
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
          color: Theme.of(context).cardTheme.color,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }
}
