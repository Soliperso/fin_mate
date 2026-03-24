import 'package:flutter/material.dart';

/// A [FloatingActionButtonAnimator] that shows/hides the FAB instantly
/// with no scale, rotation, or any transition animation.
///
/// Use this on any [Scaffold] whose FAB is conditionally shown based on
/// async state, to prevent the unwanted spin/rotate entrance animation
/// that Flutter plays every time the FAB widget appears.
class InstantFabAnimator extends FloatingActionButtonAnimator {
  const InstantFabAnimator();

  @override
  Offset getOffset({
    required Offset begin,
    required Offset end,
    required double progress,
  }) =>
      end;

  @override
  Animation<double> getScaleAnimation({required Animation<double> parent}) =>
      const AlwaysStoppedAnimation(1.0);

  @override
  Animation<double> getRotationAnimation({required Animation<double> parent}) =>
      const AlwaysStoppedAnimation(0.0);
}
