import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/cycle/cycle_calculator.dart';

/// A circular "cycle wheel": a ring divided into arcs for each cycle phase,
/// day numbers spaced around it, and the current day highlighted — a visual
/// companion to the plain-text phase display already on `CycleScreen`, not a
/// replacement for it (the text stays the accessible/localized source of
/// truth). Renders a muted placeholder ring when nothing has been logged yet.
class CyclePhaseWheel extends StatelessWidget {
  final List<DateTime> periodStarts;
  final DateTime? now;

  const CyclePhaseWheel({super.key, required this.periodStarts, this.now});

  static const _phaseColors = {
    CyclePhase.menstrual: Color(0xFFE0574F),
    CyclePhase.follicular: Color(0xFF5AA9C7),
    CyclePhase.ovulation: Color(0xFF8BA83F),
    CyclePhase.luteal: Color(0xFFC97B98),
  };

  @override
  Widget build(BuildContext context) {
    final position = currentCyclePosition(periodStarts, now: now);
    final scheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _CyclePhaseWheelPainter(
          cycleLength: position?.cycleLength ?? 28,
          currentDay: position?.dayInCycle,
          phaseColors: _phaseColors,
          placeholderColor: scheme.outlineVariant,
          labelColor: scheme.onSurfaceVariant,
          textDirection: Directionality.of(context),
        ),
        child: Center(
          child: position == null
              ? Icon(Icons.calendar_today_outlined, color: scheme.onSurfaceVariant, size: 28)
              : Text(
                  '${position.dayInCycle + 1}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
        ),
      ),
    );
  }
}

class _CyclePhaseWheelPainter extends CustomPainter {
  final int cycleLength;
  final int? currentDay;
  final Map<CyclePhase, Color> phaseColors;
  final Color placeholderColor;
  final Color labelColor;
  final TextDirection textDirection;

  _CyclePhaseWheelPainter({
    required this.cycleLength,
    required this.currentDay,
    required this.phaseColors,
    required this.placeholderColor,
    required this.labelColor,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = size.shortestSide / 2;
    final ringThickness = outerRadius * 0.2;
    final ringRadius = outerRadius - ringThickness / 2 - 20;
    final anglePerDay = 2 * math.pi / cycleLength;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringThickness;

    for (var day = 0; day < cycleLength; day++) {
      final isToday = day == currentDay;
      ringPaint.color = currentDay == null
          ? placeholderColor
          : phaseColors[phaseForDayInCycle(day, cycleLength)]!
              .withValues(alpha: isToday ? 1 : 0.45);
      final startAngle = -math.pi / 2 + day * anglePerDay;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle,
        anglePerDay * 1.05, // slight overlap so adjacent arcs don't leave hairline gaps
        false,
        ringPaint,
      );
    }

    // Day-number labels: every 5th day plus day 1, kept sparse so labels
    // don't overlap on longer cycles; the current day always gets one too.
    final labelDays = <int>{
      for (var day = 0; day < cycleLength; day += 5) day,
      if (currentDay != null) currentDay!,
    };
    for (final day in labelDays) {
      final angle = -math.pi / 2 + (day + 0.5) * anglePerDay;
      final labelCenter = center +
          Offset(math.cos(angle), math.sin(angle)) * (ringRadius + ringThickness / 2 + 14);
      final isToday = day == currentDay;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${day + 1}',
          style: TextStyle(
            color: isToday ? labelColor : labelColor.withValues(alpha: 0.7),
            fontSize: isToday ? 13 : 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: textDirection,
      )..layout();
      textPainter.paint(
        canvas,
        labelCenter - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Current-day marker on the ring itself.
    if (currentDay != null) {
      final markerAngle = -math.pi / 2 + (currentDay! + 0.5) * anglePerDay;
      final markerCenter = center + Offset(math.cos(markerAngle), math.sin(markerAngle)) * ringRadius;
      canvas.drawCircle(markerCenter, ringThickness * 0.34, Paint()..color = Colors.white);
      canvas.drawCircle(
        markerCenter,
        ringThickness * 0.34,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CyclePhaseWheelPainter oldDelegate) {
    return oldDelegate.cycleLength != cycleLength ||
        oldDelegate.currentDay != currentDay ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.placeholderColor != placeholderColor;
  }
}
