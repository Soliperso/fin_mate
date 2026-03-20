import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class GoalAchievementDialog extends StatefulWidget {
  final String goalName;

  const GoalAchievementDialog({super.key, required this.goalName});

  @override
  State<GoalAchievementDialog> createState() => _GoalAchievementDialogState();
}

class _GoalAchievementDialogState extends State<GoalAchievementDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Confetto> _particles;

  static const _colors = [
    Color(0xFF20808D), // brand teal
    Color(0xFFFFD700), // gold
    Color(0xFFFF6B6B), // coral
    Color(0xFF4ECDC4), // mint
    Color(0xFFFFE66D), // yellow
    Color(0xFFA8E6CF), // light green
    Color(0xFFFF8B94), // pink
    Color(0xFF6C5CE7), // purple
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _particles = List.generate(80, (_) => _Confetto(
      x: rng.nextDouble(),
      yStart: -rng.nextDouble() * 0.5, // stagger start above screen
      speed: 0.25 + rng.nextDouble() * 0.55,
      size: 6.0 + rng.nextDouble() * 10.0,
      color: _colors[rng.nextInt(_colors.length)],
      isCircle: rng.nextBool(),
      drift: (rng.nextDouble() - 0.5) * 0.25,
      rotationSpeed: (rng.nextDouble() - 0.5) * 8,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Confetti layer — full screen, non-interactive
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => CustomPaint(
                      painter: _ConfettiPainter(_particles, _controller.value),
                    ),
                  ),
                ),
              ),

              // Card — tapping inside does NOT dismiss
              GestureDetector(
                onTap: () {}, // absorb taps so they don't reach the outer dismiss
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xl,
                    vertical: AppSizes.xxl,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.xl),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardBackgroundDark : Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy icon
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.warning,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        const Text(
                          'Goal Achieved! 🎉',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          'You\'ve reached your savings target for "${widget.goalName}". Amazing work!',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.xl),
                        SizedBox(
                          width: double.infinity,
                          height: AppSizes.buttonHeightMd,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.brandTeal,
                              foregroundColor: AppColors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Awesome!',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _Confetto {
  final double x;
  final double yStart;
  final double speed;
  final double size;
  final Color color;
  final bool isCircle;
  final double drift;
  final double rotationSpeed;

  const _Confetto({
    required this.x,
    required this.yStart,
    required this.speed,
    required this.size,
    required this.color,
    required this.isCircle,
    required this.drift,
    required this.rotationSpeed,
  });
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final List<_Confetto> particles;
  final double progress; // 0.0 → 1.0, repeating

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // t: normalised vertical position 0..1 with stagger
      final t = ((p.yStart + progress * p.speed) % 1.0 + 1.0) % 1.0;
      final y = t * (size.height + p.size * 2) - p.size;
      final x = p.x * size.width +
          sin(progress * 2 * pi * p.rotationSpeed) * p.drift * size.width;

      // Fade in near top, fade out near bottom
      final opacity = (t < 0.1 ? t / 0.1 : (t > 0.85 ? (1.0 - t) / 0.15 : 1.0))
          .clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotationSpeed * pi);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
