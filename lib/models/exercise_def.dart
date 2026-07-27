import 'package:flutter/widgets.dart' show IconData;

/// What's in your hand while doing the exercise — the "equipment" tier of
/// the icon system documented in docs/ICON_REGISTRY.md. Barbell, dumbbell,
/// kettlebell, and cable/machine all have a distinct icon glyph in Lucide;
/// the rest fall back to the category icon.
enum Equipment {
  barbell,
  dumbbell,
  kettlebell,
  cableMachine,
  bodyweight,
  band,
  bench,
  other
}

/// The direction/pattern of motion — the "movement badge" tier, rendered as
/// a small corner overlay on top of the equipment icon by `ExerciseIcon`
/// (lib/widgets/exercise_icon.dart). Combined with [Equipment], this is what
/// gives visually near-identical exercises (e.g. every barbell press
/// variant) a distinct look without needing a bespoke pictogram per
/// exercise — see docs/ICON_REGISTRY.md §2 for why bespoke pictograms
/// don't exist in any icon library.
enum MovementBadge {
  press,
  curl,
  pull,
  pulldown,
  extension,
  raise,
  squat,
  hipThrust,
  twist,
  carry,
  jump,
  hold,
  swing,
  rotationalPress,
  roll,
}

/// How an exercise is logged during a workout. `null` on [ExerciseDef]/
/// [CustomExercise] means "derive it from category instead" — the original
/// behavior (`category == 'Cardio'`/`'Pilates'`) in
/// `ActiveWorkoutRepository`, kept as the fallback so the ~200 built-in
/// `exerciseLibrary` entries don't all need this field set by hand. Only
/// custom exercises need to set this explicitly, to opt into duration-based
/// logging without having to (mis)file themselves under Cardio/Pilates.
enum ExerciseTrackingType {
  /// Sets of reps + weight — the default for nearly every exercise.
  standard,

  /// Logged as a single duration, no sets (like today's Pilates entries).
  timed,

  /// Logged as duration + calories burned + distance (like today's Cardio
  /// entries).
  distance,
}

class ExerciseDef {
  final String name;
  final String category;
  final Equipment equipment;
  final MovementBadge? movement;

  /// Explicit override for how this exercise is logged — see
  /// [ExerciseTrackingType]. Only ever set on custom exercises today; every
  /// built-in [ExerciseDef] leaves this null and falls back to category.
  final ExerciseTrackingType? trackingType;

  /// Direct icon override, used when a specific activity has its own verified
  /// glyph (e.g. Running -> Icons.directions_run) that the equipment/category
  /// tiers can't express. Takes precedence over [equipment] and [category].
  final IconData? icon;

  /// Link to a verified YouTube tutorial for this movement's form, sourced
  /// from EXERCISE_VIDEO_REGISTRY.md. Null when no verified video was found.
  final String? videoUrl;

  /// True for exercises trained one side at a time (e.g. single-arm curls) —
  /// the active-workout logger tracks a left and a right set per numbered
  /// set instead of one bilateral set. See `isUnilateralExercise`.
  final bool unilateral;

  const ExerciseDef({
    required this.name,
    required this.category,
    this.equipment = Equipment.other,
    this.movement,
    this.icon,
    this.videoUrl,
    this.unilateral = false,
    this.trackingType,
  });
}
