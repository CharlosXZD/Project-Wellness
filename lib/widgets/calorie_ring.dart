import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Eaten-vs-target ring with the remaining (or over) amount in the middle.
/// Past 100% the overflow wraps round in the error color, so "over" reads
/// at a glance instead of just looking like a full ring.
class CalorieRing extends StatelessWidget {
  final double eaten;
  final double? target;
  final double size;
  final Color color;

  const CalorieRing({
    super.key,
    required this.eaten,
    required this.target,
    required this.color,
    this.size = 128,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final target = this.target;
    final remaining = target == null ? null : target - eaten;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: target == null || target <= 0 ? 0 : eaten / target),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, fraction, _) => CustomPaint(
          painter: _RingPainter(
            fraction: fraction,
            color: color,
            overColor: scheme.error,
            trackColor: scheme.onSurface.withValues(alpha: 0.08),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  remaining == null ? '${eaten.round()}' : '${remaining.abs().round()}',
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  remaining == null
                      ? 'kcal eaten'
                      : remaining >= 0
                          ? 'kcal left'
                          : 'kcal over',
                  style: textTheme.labelMedium?.copyWith(
                    color: remaining != null && remaining < 0 ? scheme.error : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color overColor;
  final Color trackColor;

  _RingPainter({
    required this.fraction,
    required this.color,
    required this.overColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.09;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - stroke / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = trackColor);
    final main = fraction.clamp(0.0, 1.0);
    if (main > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * main, false, paint..color = color);
    }
    final over = (fraction - 1).clamp(0.0, 1.0);
    if (over > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * over, false, paint..color = overColor);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction || old.color != color || old.trackColor != trackColor;
}
