import 'dart:math';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  late List<_Shell> _shells;

  // Realistic colour palettes: [hot core colour, cooled star colour]
  static const _palettes = [
    [Color(0xFFFFE066), Color(0xFFFFAA00)], // gold
    [Color(0xFFFF6060), Color(0xFFCC0000)], // red
    [Color(0xFF80DFFF), Color(0xFF0099FF)], // blue
    [Color(0xFF80FF80), Color(0xFF00CC00)], // green
    [Color(0xFFFF80FF), Color(0xFFCC00CC)], // purple
    [Color(0xFFFFFFCC), Color(0xFFFFDD44)], // silver-white
    [Color(0xFFFFB060), Color(0xFFFF5500)], // orange
    [Color(0xFF80FFEE), Color(0xFF00BBAA)], // teal
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    final rng = Random();
    _shells = List.generate(11, (i) {
      final palette = _palettes[rng.nextInt(_palettes.length)];
      final starCount = 65 + rng.nextInt(30); // 65–95 stars per shell
      // Evenly distribute angles then add small jitter for natural look
      return _Shell(
        x: 0.06 + rng.nextDouble() * 0.88,
        burstY: 0.06 + rng.nextDouble() * 0.42,
        launchOffset: i / 11.0,
        coreColor: palette[0],
        outerColor: palette[1],
        stars: List.generate(starCount, (j) {
          final base = (j / starCount) * 2 * pi;
          return _Star(
            angle: base + (rng.nextDouble() - 0.5) * (2 * pi / starCount * 0.5),
            speed: 0.55 + rng.nextDouble() * 0.90,
            size: 2.8 + rng.nextDouble() * 3.2,
            trail: rng.nextDouble() < 0.72,
          );
        }),
      );
    });
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
              // Fireworks canvas — full screen, non-interactive
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => CustomPaint(
                      painter: _FireworksPainter(_shells, _controller.value),
                    ),
                  ),
                ),
              ),

              // Card — tapping inside does NOT dismiss
              GestureDetector(
                onTap: () {},
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
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.rosette,
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
                          'You\'ve reached your savings target for '
                          '"${widget.goalName}". Amazing work!',
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
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/goals');
                          },
                          child: const Text(
                            'Start a New Goal',
                            style: TextStyle(
                              color: AppColors.brandTeal,
                              fontWeight: FontWeight.w500,
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

// ── Data models ───────────────────────────────────────────────────────────────

class _Star {
  final double angle;
  final double speed;
  final double size;
  final bool trail;

  const _Star({
    required this.angle,
    required this.speed,
    required this.size,
    required this.trail,
  });
}

class _Shell {
  final double x;            // 0..1 normalised horizontal launch position
  final double burstY;       // 0..1 normalised vertical burst height (0 = top)
  final double launchOffset; // 0..1 phase offset within the animation loop
  final Color coreColor;     // white-hot colour shown at initial burst
  final Color outerColor;    // cooled star colour
  final List<_Star> stars;

  const _Shell({
    required this.x,
    required this.burstY,
    required this.launchOffset,
    required this.coreColor,
    required this.outerColor,
    required this.stars,
  });
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _FireworksPainter extends CustomPainter {
  final List<_Shell> shells;
  final double progress; // 0..1 repeating

  // Each shell occupies this fraction of the loop
  static const _shellDuration = 0.54;
  // Rocket ascent is this fraction of the shell lifetime
  static const _rocketPhase = 0.20;
  // Air-resistance drag coefficient (higher = decelerates faster)
  static const _drag = 1.6;

  const _FireworksPainter(this.shells, this.progress);

  /// Position of a particle at normalised time [t] under exponential drag.
  /// x(t) = v₀ × ∫₀ᵗ e^(−k·s) ds  =  v₀ × (1 − e^(−k·t)) / k
  static double _dp(double v0, double t) =>
      v0 * (1.0 - exp(-_drag * t)) / _drag;

  @override
  void paint(Canvas canvas, Size size) {
    for (final shell in shells) {
      final raw = ((progress - shell.launchOffset) % 1.0 + 1.0) % 1.0;
      if (raw > _shellDuration) continue;
      final ft = raw / _shellDuration; // 0..1 within this shell's life

      final bx = shell.x * size.width;
      final by = shell.burstY * size.height;

      if (ft < _rocketPhase) {
        _drawRocket(canvas, size, shell, ft, bx, by);
      } else {
        _drawBurst(canvas, size, shell, ft, bx, by);
      }
    }
  }

  // ── Rocket ascent ────────────────────────────────────────────────────────────

  void _drawRocket(
    Canvas canvas, Size size, _Shell shell, double ft, double bx, double by,
  ) {
    // Ease-in: rocket accelerates as it rises
    final rt = ft / _rocketPhase;
    final t = rt * rt; // quadratic ease-in

    final startY = size.height * 1.05; // just below screen
    final cy = startY + (by - startY) * t;

    // ── Smoke trail (faint grey dots left behind) ──────────────────────────
    final smokeCount = 6;
    for (int s = 1; s <= smokeCount; s++) {
      final st = (t - s * 0.04).clamp(0.0, 1.0);
      final sy = startY + (by - startY) * st;
      final smokeAlpha = (1.0 - s / smokeCount) * 0.22;
      canvas.drawCircle(
        Offset(bx, sy),
        2.5 + s * 0.4,
        Paint()
          ..color = Colors.grey.withValues(alpha: smokeAlpha)
          ..style = PaintingStyle.fill,
      );
    }

    // ── Bright exhaust flame ───────────────────────────────────────────────
    // Outer orange glow
    canvas.drawCircle(
      Offset(bx, cy + 6),
      9,
      Paint()
        ..color = shell.outerColor.withValues(alpha: 0.30)
        ..style = PaintingStyle.fill,
    );
    // Inner flame
    canvas.drawCircle(
      Offset(bx, cy + 3),
      5,
      Paint()
        ..color = shell.coreColor.withValues(alpha: 0.70)
        ..style = PaintingStyle.fill,
    );

    // ── Rocket head ───────────────────────────────────────────────────────
    // Coloured glow
    canvas.drawCircle(
      Offset(bx, cy),
      7,
      Paint()
        ..color = shell.outerColor.withValues(alpha: 0.40)
        ..style = PaintingStyle.fill,
    );
    // White-hot core
    canvas.drawCircle(
      Offset(bx, cy),
      3.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  // ── Burst ─────────────────────────────────────────────────────────────────

  void _drawBurst(
    Canvas canvas, Size size, _Shell shell, double ft, double bx, double by,
  ) {
    final bt = (ft - _rocketPhase) / (1.0 - _rocketPhase); // 0..1 within burst

    // ── Expanding flash ring ──────────────────────────────────────────────
    if (bt < 0.16) {
      final flt = bt / 0.16;
      // Outer ring
      canvas.drawCircle(
        Offset(bx, by),
        70 * flt,
        Paint()
          ..color = shell.coreColor.withValues(alpha: (1.0 - flt) * 0.55)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke,
      );
      // White hot centre ball
      canvas.drawCircle(
        Offset(bx, by),
        22 * (1.0 - flt),
        Paint()
          ..color = Colors.white.withValues(alpha: (1.0 - flt) * 0.92)
          ..style = PaintingStyle.fill,
      );
    }

    // ── Stars ─────────────────────────────────────────────────────────────
    // Spread: how far a speed=1 star travels at the end of the burst
    final spread = size.width * 0.70;
    // Gravity: total downward pixel displacement at bt=1
    final gravity = size.height * 0.29;

    for (final star in shell.stars) {
      final vx = cos(star.angle) * star.speed;
      final vy = sin(star.angle) * star.speed;

      // Current position — drag physics + gravity
      final dpNow  = _dp(1.0, bt);
      final px = bx + vx * dpNow * spread;
      final py = by + vy * dpNow * spread + gravity * bt * bt;

      // ── Colour temperature ─────────────────────────────────────────────
      // Stars start white-hot, cool to their colour, then fade/dim
      const heatDuration = 0.18; // fraction of burst where stars are white-hot
      final heatT = (bt / heatDuration).clamp(0.0, 1.0);
      final starColor = Color.lerp(Colors.white, shell.coreColor, heatT)!;

      // Opacity: hold full brightness until halfway, then taper to black
      final opacity = bt < 0.50
          ? 1.0
          : (1.0 - (bt - 0.50) / 0.50).clamp(0.0, 1.0);

      // ── Trail ─────────────────────────────────────────────────────────
      if (star.trail) {
        // Trail tip is the star's position a moment earlier
        // Because of drag, the gap shrinks naturally as the star slows
        final trailBt = (bt - 0.06).clamp(0.0, 1.0);
        final dpTrail = _dp(1.0, trailBt);
        final tpx = bx + vx * dpTrail * spread;
        final tpy = by + vy * dpTrail * spread + gravity * trailBt * trailBt;

        // Outer coloured trail
        canvas.drawLine(
          Offset(tpx, tpy),
          Offset(px, py),
          Paint()
            ..color = shell.outerColor.withValues(alpha: opacity * 0.55)
            ..strokeWidth = star.size * 0.95
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
        // Inner bright streak
        canvas.drawLine(
          Offset(tpx, tpy),
          Offset(px, py),
          Paint()
            ..color = starColor.withValues(alpha: opacity * 0.75)
            ..strokeWidth = star.size * 0.42
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
      }

      // ── Star head ─────────────────────────────────────────────────────
      // Soft coloured glow
      canvas.drawCircle(
        Offset(px, py),
        star.size * 1.5,
        Paint()
          ..color = shell.outerColor.withValues(alpha: opacity * 0.22)
          ..style = PaintingStyle.fill,
      );
      // Coloured body
      canvas.drawCircle(
        Offset(px, py),
        star.size * 0.75,
        Paint()
          ..color = starColor.withValues(alpha: opacity * 0.95)
          ..style = PaintingStyle.fill,
      );
      // Bright white-hot centre (fades as star cools)
      if (bt < heatDuration * 2) {
        canvas.drawCircle(
          Offset(px, py),
          star.size * 0.35,
          Paint()
            ..color = Colors.white
                .withValues(alpha: opacity * (1.0 - bt / (heatDuration * 2)).clamp(0.0, 1.0))
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => old.progress != progress;
}
