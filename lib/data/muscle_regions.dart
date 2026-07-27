import 'package:flutter/material.dart';

import 'exercise_library.dart';
import '../models/workout_session.dart';

/// The 13 muscle groups the Body Rank diagram tracks. Six of them
/// (chest/shoulders/biceps/triceps/forearms/abs) map 1:1 onto an existing
/// `ExerciseDef.category` — see [_categoryDerivedRegions]. The other seven
/// only exist because the "Back" and "Legs" categories each bundle several
/// distinct muscles, so those need explicit per-exercise assignment below.
enum MuscleRegion {
  chest,
  shoulders,
  biceps,
  triceps,
  forearms,
  abs,
  lats,
  traps,
  lowerBack,
  glutes,
  quads,
  hamstrings,
  calves,
}

extension MuscleRegionLabel on MuscleRegion {
  String get label {
    switch (this) {
      case MuscleRegion.chest:
        return 'Chest';
      case MuscleRegion.shoulders:
        return 'Shoulders';
      case MuscleRegion.biceps:
        return 'Biceps';
      case MuscleRegion.triceps:
        return 'Triceps';
      case MuscleRegion.forearms:
        return 'Forearms';
      case MuscleRegion.abs:
        return 'Abs';
      case MuscleRegion.lats:
        return 'Lats';
      case MuscleRegion.traps:
        return 'Traps';
      case MuscleRegion.lowerBack:
        return 'Lower Back';
      case MuscleRegion.glutes:
        return 'Glutes';
      case MuscleRegion.quads:
        return 'Quads';
      case MuscleRegion.hamstrings:
        return 'Hamstrings';
      case MuscleRegion.calves:
        return 'Calves';
    }
  }
}

/// A category that maps 1:1 onto a [MuscleRegion] — every exercise in it
/// counts toward that region, no per-exercise tagging needed.
const _categoryDerivedRegions = {
  'Chest': MuscleRegion.chest,
  'Shoulders': MuscleRegion.shoulders,
  'Biceps': MuscleRegion.biceps,
  'Triceps': MuscleRegion.triceps,
  'Forearms': MuscleRegion.forearms,
  'Core': MuscleRegion.abs,
};

// "Back" bundles lats/traps; most pulling/pulldown movements are
// lat-dominant, shrugs and face pulls are traps-dominant.
const _latsExercises = {
  'Pull-Up',
  'Chin-Up',
  'Lat Pulldown',
  'Barbell Row',
  'Dumbbell Row',
  'T-Bar Row',
  'Seated Cable Row',
  'Front Lever',
  'Muscle-Up',
  'Straight-Arm Pulldown',
  'Chest-Supported Row',
  'Inverted Row',
};
const _trapsExercises = {'Face Pull', 'Shrugs'};

// "Legs" bundles quads/hamstrings/glutes/calves. The hip-hinge family also
// loads the lower back synergistically, so those contribute to two regions.
const _quadsExercises = {
  'Back Squat',
  'Front Squat',
  'Leg Press',
  'Lunges',
  'Bulgarian Split Squat',
  'Leg Extension',
  'Goblet Squat',
  'Walking Lunge',
  'Box Squat',
  'ATG Split Squat',
  'Cossack Squat',
  'Pistol Squat',
  'Hack Squat',
  'Step-Up',
  'Sissy Squat',
  'Reverse Lunge',
  'Hip Adduction Machine',
};
const _hamstringsExercises = {
  'Romanian Deadlift',
  'Deadlift',
  'Sumo Deadlift',
  'Good Morning',
  'Rack Pull',
  'Hyperextension',
  'Leg Curl',
  'Nordic Hamstring Curl',
};
const _glutesExercises = {
  'Romanian Deadlift',
  'Deadlift',
  'Sumo Deadlift',
  'Good Morning',
  'Rack Pull',
  'Lunges',
  'Bulgarian Split Squat',
  'Hip Thrust',
  'Walking Lunge',
  'Cossack Squat',
  'Pistol Squat',
  'Step-Up',
  'Reverse Lunge',
  'Glute Bridge',
  'Hip Abduction Machine',
};
const _calvesExercises = {'Calf Raise', 'Seated Calf Raise'};
const _lowerBackExercises = {
  'Romanian Deadlift',
  'Deadlift',
  'Sumo Deadlift',
  'Good Morning',
  'Rack Pull',
  'Hyperextension',
};

final Map<MuscleRegion, Set<String>> _manualRegionExercises = {
  MuscleRegion.lats: _latsExercises,
  MuscleRegion.traps: _trapsExercises,
  MuscleRegion.quads: _quadsExercises,
  MuscleRegion.hamstrings: _hamstringsExercises,
  MuscleRegion.glutes: _glutesExercises,
  MuscleRegion.calves: _calvesExercises,
  MuscleRegion.lowerBack: _lowerBackExercises,
};

/// Every exercise name that counts toward [region] — computed once and
/// cached, combining the category-derived regions with the manual
/// Back/Legs splits above.
final Map<MuscleRegion, Set<String>> _regionExerciseNames = {
  for (final region in MuscleRegion.values)
    region: {
      for (final exercise in exerciseLibrary)
        if (_categoryDerivedRegions[exercise.category] == region) exercise.name,
      ...?_manualRegionExercises[region],
    },
};

/// Every exercise name (built-in library, sorted) that counts toward
/// [region] — the public read of [_regionExerciseNames], for UI that wants
/// to show "what trains this muscle" (e.g. tapping a region on Body Rank).
List<String> exerciseNamesForRegion(MuscleRegion region) =>
    _regionExerciseNames[region]!.toList()..sort();

/// Lifetime `weight * reps` summed across every set of every exercise
/// mapped to [region] — same volume math as `_maxSessionVolumeKg` in
/// `lib/data/medal_catalog.dart`, just accumulated across all sessions
/// instead of maxed per-session.
double regionVolumeKg(MuscleRegion region, List<WorkoutSession> sessions) {
  final names = _regionExerciseNames[region]!;
  var total = 0.0;
  for (final session in sessions) {
    for (final exercise in session.exercises) {
      if (!names.contains(exercise.exerciseName)) continue;
      for (final set in exercise.sets) {
        total += set.weightKg * set.reps;
      }
    }
  }
  return total;
}

/// Cosmetic-only rarity ladder for Body Rank — separate from [MedalTier]
/// since this is a 9-step ladder (E through Ultra) rather than 4.
enum MuscleRankTier {
  novice,
  trainee,
  amateur,
  competent,
  advanced,
  elite,
  master,
  grandmaster,
  legendary
}

extension MuscleRankTierX on MuscleRankTier {
  String get code {
    switch (this) {
      case MuscleRankTier.novice:
        return 'E';
      case MuscleRankTier.trainee:
        return 'D';
      case MuscleRankTier.amateur:
        return 'C';
      case MuscleRankTier.competent:
        return 'B';
      case MuscleRankTier.advanced:
        return 'A';
      case MuscleRankTier.elite:
        return 'S';
      case MuscleRankTier.master:
        return 'SS';
      case MuscleRankTier.grandmaster:
        return 'SSS';
      case MuscleRankTier.legendary:
        return 'Ultra';
    }
  }

  String get displayName {
    switch (this) {
      case MuscleRankTier.novice:
        return 'Novice';
      case MuscleRankTier.trainee:
        return 'Trainee';
      case MuscleRankTier.amateur:
        return 'Amateur';
      case MuscleRankTier.competent:
        return 'Competent';
      case MuscleRankTier.advanced:
        return 'Advanced';
      case MuscleRankTier.elite:
        return 'Elite';
      case MuscleRankTier.master:
        return 'Master';
      case MuscleRankTier.grandmaster:
        return 'Grandmaster';
      case MuscleRankTier.legendary:
        return 'Legendary';
    }
  }

  /// Text/icon color to put on top of [color] — [MuscleRankTier.novice]'s
  /// near-white fill needs a dark label instead of the white used on every
  /// other (much darker) tier color.
  Color get onColor =>
      this == MuscleRankTier.novice ? const Color(0xFF424242) : Colors.white;

  /// Flat representative color — used for text/badges. [MuscleRankTier.legendary]
  /// gets a real prismatic gradient in the body diagram itself (see
  /// `lib/widgets/muscle_body_diagram.dart`); this is just its label color.
  Color get color {
    switch (this) {
      case MuscleRankTier.novice:
        return const Color(0xFFE0E0E0);
      case MuscleRankTier.trainee:
        return const Color(0xFF8BC34A);
      case MuscleRankTier.amateur:
        return const Color(0xFF26A69A);
      case MuscleRankTier.competent:
        return const Color(0xFF42A5F5);
      case MuscleRankTier.advanced:
        return const Color(0xFFAB47BC);
      case MuscleRankTier.elite:
        return const Color(0xFFFF9800);
      case MuscleRankTier.master:
        return const Color(0xFFEF5350);
      case MuscleRankTier.grandmaster:
        return const Color(0xFFFFD54F);
      case MuscleRankTier.legendary:
        return const Color(0xFFD500F9);
    }
  }
}

/// Lifetime-volume thresholds (kg) for each tier above [MuscleRankTier.novice]
/// — a plain, easy-to-retune starting calibration, not a scientifically
/// derived one.
const Map<MuscleRankTier, double> _baseThresholdsKg = {
  MuscleRankTier.trainee: 1500,
  MuscleRankTier.amateur: 4000,
  MuscleRankTier.competent: 10000,
  MuscleRankTier.advanced: 25000,
  MuscleRankTier.elite: 60000,
  MuscleRankTier.master: 150000,
  MuscleRankTier.grandmaster: 350000,
  MuscleRankTier.legendary: 800000,
};

/// Divides a region's raw volume before comparing it against
/// [_baseThresholdsKg] — naturally low-load regions (forearms, abs, calves)
/// get a smaller divisor so a proportionally similar amount of effort ranks
/// up at roughly the same rate as naturally high-load regions (quads, chest).
const Map<MuscleRegion, double> _regionMultiplier = {
  MuscleRegion.quads: 2.5,
  MuscleRegion.chest: 1.8,
  MuscleRegion.lats: 1.6,
  MuscleRegion.hamstrings: 1.5,
  MuscleRegion.glutes: 1.5,
  MuscleRegion.shoulders: 1.0,
  MuscleRegion.lowerBack: 0.9,
  MuscleRegion.triceps: 0.9,
  MuscleRegion.traps: 0.8,
  MuscleRegion.biceps: 0.8,
  MuscleRegion.calves: 0.7,
  MuscleRegion.abs: 0.5,
  MuscleRegion.forearms: 0.4,
};

/// A region's current tier plus progress (0..1) toward the next one. Fully
/// ranked ([MuscleRankTier.legendary] reached) reports `progress == 1.0`.
class MuscleRank {
  final MuscleRankTier tier;
  final double progress;
  final double volumeKg;

  const MuscleRank(
      {required this.tier, required this.progress, required this.volumeKg});
}

MuscleRank rankFor(MuscleRegion region, List<WorkoutSession> sessions) {
  final rawVolume = regionVolumeKg(region, sessions);
  final effectiveVolume = rawVolume / _regionMultiplier[region]!;

  MuscleRankTier tier = MuscleRankTier.novice;
  double lowerBound = 0;
  double? nextThreshold = _baseThresholdsKg[MuscleRankTier.trainee];
  for (final candidate in MuscleRankTier.values) {
    final threshold = _baseThresholdsKg[candidate];
    if (threshold == null) continue; // novice has no threshold of its own
    if (effectiveVolume < threshold) {
      nextThreshold = threshold;
      break;
    }
    tier = candidate;
    lowerBound = threshold;
    nextThreshold = null;
  }

  final progress = nextThreshold == null
      ? 1.0
      : ((effectiveVolume - lowerBound) / (nextThreshold - lowerBound))
          .clamp(0.0, 1.0);

  return MuscleRank(tier: tier, progress: progress, volumeKg: rawVolume);
}

/// Mean tier index across all 13 regions, rounded down — a single headline
/// stat for the top of the Body Rank screen.
MuscleRankTier overallRank(List<WorkoutSession> sessions) {
  final indices = [
    for (final region in MuscleRegion.values)
      rankFor(region, sessions).tier.index,
  ];
  final meanIndex = indices.reduce((a, b) => a + b) / indices.length;
  return MuscleRankTier.values[meanIndex.floor()];
}
