import 'package:flutter/material.dart';

import '../data/exercise_library.dart';
import '../models/exercise_def.dart';

/// Small overlay glyph shown in the bottom-right corner of the equipment
/// icon, indicating the movement pattern. Every name here is a long-stable
/// classic Material icon (no new dependency). See docs/ICON_REGISTRY.md §5c.
IconData? badgeIconFor(MovementBadge? movement) {
  switch (movement) {
    case null:
      return null;
    case MovementBadge.press:
      return Icons.arrow_upward;
    case MovementBadge.curl:
      return Icons.rotate_left;
    case MovementBadge.pull:
      return Icons.arrow_back;
    case MovementBadge.pulldown:
      return Icons.arrow_downward;
    case MovementBadge.extension:
      return Icons.call_made;
    case MovementBadge.raise:
      return Icons.open_in_full;
    case MovementBadge.squat:
      return Icons.expand_more;
    case MovementBadge.hipThrust:
      return Icons.unfold_more;
    case MovementBadge.twist:
      return Icons.rotate_right;
    case MovementBadge.carry:
      return Icons.directions_walk;
    case MovementBadge.jump:
      return Icons.bolt;
    case MovementBadge.hold:
      return Icons.pause_circle_outline;
    case MovementBadge.swing:
      return Icons.swap_vert;
    case MovementBadge.rotationalPress:
      return Icons.sync;
    case MovementBadge.roll:
      return Icons.autorenew;
  }
}

/// Renders an exercise's equipment icon with its movement badge overlaid in
/// the bottom-right corner, entirely inside a `size` x `size` box so it drops
/// into any spot a plain `Icon` currently occupies without changing layout.
/// Below ~20px the badge is dropped rather than shrunk to illegibility.
class ExerciseIcon extends StatelessWidget {
  final ExerciseDef exercise;
  final double size;
  final Color? color;

  const ExerciseIcon({super.key, required this.exercise, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    final base = Icon(iconForExercise(exercise), size: size, color: resolvedColor);
    final badge = badgeIconFor(exercise.movement);
    if (badge == null || size < 20) return base;

    final badgeDiameter = size * 0.46;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          base,
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: badgeDiameter,
              height: badgeDiameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Icon(badge, size: badgeDiameter * 0.7, color: resolvedColor),
            ),
          ),
        ],
      ),
    );
  }
}
