import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Animated success checkmark widget
class SuccessAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  final double size;
  final Color? color;

  const SuccessAnimation({
    super.key,
    this.onComplete,
    this.size = 100,
    this.color,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );

    _scaleController.forward().then((_) {
      _checkController.forward().then((_) {
        if (widget.onComplete != null) {
          Future.delayed(const Duration(milliseconds: 500), widget.onComplete);
        }
      });
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.success;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: AnimatedBuilder(
          animation: _checkAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _CheckmarkPainter(
                progress: _checkAnimation.value,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final checkWidth = size.width * 0.6;
    final checkHeight = size.height * 0.6;
    final offsetX = (size.width - checkWidth) / 2;
    final offsetY = (size.height - checkHeight) / 2;

    // First segment (short line)
    final segment1End = 0.4;
    final segment1X = offsetX + checkWidth * 0.3;
    final segment1Y = offsetY + checkHeight * 0.5;

    // Second segment (long line)
    final segment2X = offsetX + checkWidth;
    final segment2Y = offsetY + checkHeight * 0.2;

    if (progress <= segment1End) {
      final segmentProgress = progress / segment1End;
      path.moveTo(offsetX, offsetY + checkHeight * 0.4);
      path.lineTo(
        offsetX + (segment1X - offsetX) * segmentProgress,
        offsetY + checkHeight * 0.4 + (segment1Y - offsetY - checkHeight * 0.4) * segmentProgress,
      );
    } else {
      final segmentProgress = (progress - segment1End) / (1 - segment1End);
      path.moveTo(offsetX, offsetY + checkHeight * 0.4);
      path.lineTo(segment1X, segment1Y);
      path.lineTo(
        segment1X + (segment2X - segment1X) * segmentProgress,
        segment1Y + (segment2Y - segment1Y) * segmentProgress,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Success dialog with animation
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onDismiss;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    Duration autoDismissDuration = const Duration(seconds: 2),
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    ).then((_) {
      return Future.delayed(autoDismissDuration);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SuccessAnimation(
              size: 80,
              onComplete: () {
                if (onDismiss != null) {
                  Future.delayed(
                    const Duration(milliseconds: 800),
                    onDismiss,
                  );
                }
              },
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple success snackbar
class SuccessSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
  }
}

/// Error snackbar for consistency
class ErrorSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
