import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/exercise_def.dart';

const List<String> exerciseCategories = [
  'Chest',
  'Back',
  'Legs',
  'Shoulders',
  'Biceps',
  'Triceps',
  'Forearms',
  'Core',
  'Cardio',
  'Pilates',
  'Yoga',
  'Mobility',
  'Full Body',
];

IconData iconForCategory(String category) {
  switch (category) {
    case 'Chest':
      return Icons.fitness_center;
    case 'Back':
      return Icons.rowing;
    case 'Legs':
      return Icons.directions_run;
    case 'Shoulders':
      return Icons.accessibility_new;
    case 'Biceps':
      return Icons.sports_gymnastics;
    case 'Triceps':
      return Icons.sports_martial_arts;
    case 'Forearms':
      return Icons.back_hand;
    case 'Core':
      return Icons.self_improvement;
    case 'Cardio':
      return Icons.directions_bike;
    case 'Pilates':
      return Icons.spa;
    case 'Yoga':
      return Icons.self_improvement;
    case 'Mobility':
      return Icons.straighten;
    case 'Full Body':
      return Icons.accessibility;
    default:
      return Icons.add_circle_outline;
  }
}

/// Tier-2 equipment icon, via `lucide_icons_flutter` (verified to compile
/// against this Flutter SDK — `material_design_icons_flutter` and
/// `phosphor_flutter` both fail, see docs/ICON_REGISTRY.md §2). Lucide has
/// no literal "barbell" glyph either, so barbell/kettlebell share `weight`;
/// dumbbell and cable/machine get their own literal glyphs. Bodyweight gets
/// `footprints`. Band/bench/other have no honest dedicated glyph and fall
/// back to the category icon.
IconData? _equipmentIcon(Equipment equipment) {
  switch (equipment) {
    case Equipment.barbell:
    case Equipment.kettlebell:
      return LucideIcons.weight;
    case Equipment.dumbbell:
      return LucideIcons.dumbbell;
    case Equipment.cableMachine:
      return LucideIcons.cable;
    case Equipment.bodyweight:
      return LucideIcons.footprints;
    case Equipment.band:
    case Equipment.bench:
    case Equipment.other:
      return null;
  }
}

/// Resolves the base icon for a single exercise: explicit override, then
/// equipment glyph, then category default. Combine with [badgeIconFor] (in
/// lib/widgets/exercise_icon.dart) via the `ExerciseIcon` widget for the
/// full equipment + movement composite — see docs/ICON_REGISTRY.md §2/§6.
IconData iconForExercise(ExerciseDef exercise) {
  return exercise.icon ?? _equipmentIcon(exercise.equipment) ?? iconForCategory(exercise.category);
}

/// Suggested categories to surface first for a given split day name.
List<String> suggestedCategoriesForDay(String dayName) {
  switch (dayName.toLowerCase()) {
    case 'push':
      return const ['Chest', 'Shoulders', 'Triceps'];
    case 'pull':
      return const ['Back', 'Biceps', 'Forearms'];
    case 'legs':
      return const ['Legs'];
    case 'upper':
      return const ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps', 'Forearms'];
    case 'lower':
      return const ['Legs'];
    case 'full body':
      return const ['Full Body', 'Legs', 'Chest', 'Back'];
    case 'chest':
      return const ['Chest'];
    case 'back':
      return const ['Back'];
    case 'shoulders':
      return const ['Shoulders'];
    case 'arms':
      return const ['Biceps', 'Triceps', 'Forearms'];
    case 'biceps':
      return const ['Biceps', 'Forearms'];
    case 'triceps':
      return const ['Triceps'];
    case 'forearms':
      return const ['Forearms', 'Biceps'];
    case 'pilates':
      return const ['Pilates'];
    case 'yoga':
      return const ['Yoga', 'Mobility'];
    case 'mobility':
      return const ['Mobility', 'Yoga'];
    default:
      return const [];
  }
}

/// Looks up the form-tutorial video for an exercise by name (as stored on
/// [TemplateExercise]/[SessionExercise], which don't carry the full
/// [ExerciseDef]). Returns null for custom, user-added exercises or any
/// library exercise without a verified video in EXERCISE_VIDEO_REGISTRY.md.
String? videoUrlForExercise(String name) {
  for (final exercise in exerciseLibrary) {
    if (exercise.name == name) return exercise.videoUrl;
  }
  return null;
}

/// Whether an exercise (looked up by name, same pattern as
/// [videoUrlForExercise]) is bodyweight-based — used by the workout logger
/// to default a fresh set to 0kg *added* weight instead of 20kg, since the
/// body itself is already the load. Returns false for custom, user-added
/// exercises (they default to the barbell/dumbbell convention instead).
bool isBodyweightExercise(String name) {
  for (final exercise in exerciseLibrary) {
    if (exercise.name == name) return exercise.equipment == Equipment.bodyweight;
  }
  return false;
}

/// Whether an exercise (looked up by name, same pattern as
/// [isBodyweightExercise]) is trained one side at a time — the active
/// workout logger tracks a left/right pair per numbered set for these
/// instead of one bilateral set. Returns false for custom exercises here;
/// the training repository's custom-exercise lookup layers on top of this.
bool isUnilateralExercise(String name) {
  for (final exercise in exerciseLibrary) {
    if (exercise.name == name) return exercise.unilateral;
  }
  return false;
}

const List<ExerciseDef> exerciseLibrary = [
  // Chest
  ExerciseDef(name: 'Barbell Bench Press', category: 'Chest', equipment: Equipment.barbell, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=ptpmRrzRtWQ'),
  ExerciseDef(name: 'Incline Bench Press', category: 'Chest', equipment: Equipment.barbell, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=5kyLUGVq_pk'),
  ExerciseDef(name: 'Decline Bench Press', category: 'Chest', equipment: Equipment.barbell, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=hz_H8xVjnuA'),
  ExerciseDef(name: 'Dumbbell Bench Press', category: 'Chest', equipment: Equipment.dumbbell, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=5Y3VZsLb1Ys'),
  ExerciseDef(name: 'Incline Dumbbell Press', category: 'Chest', equipment: Equipment.dumbbell, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=awEEyL5zGvU'),
  ExerciseDef(name: 'Dumbbell Flyes', category: 'Chest', equipment: Equipment.dumbbell, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=MJsgciiE1H0'),
  ExerciseDef(name: 'Cable Crossover', category: 'Chest', equipment: Equipment.cableMachine, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=XY6JrX1wyxk'),
  ExerciseDef(name: 'Push-Up', category: 'Chest', equipment: Equipment.bodyweight, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=Zi6c09DRGxk'),
  ExerciseDef(name: 'Chest Dip', category: 'Chest', equipment: Equipment.bodyweight, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=dX_nSOOJIsE'),
  ExerciseDef(name: 'Pec Deck Machine', category: 'Chest', equipment: Equipment.cableMachine, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=JYmszQs-mRs'),
  ExerciseDef(name: 'Landmine Press', category: 'Chest', equipment: Equipment.barbell, movement: MovementBadge.rotationalPress, videoUrl: 'https://www.youtube.com/watch?v=9OW4SONxuGI'),
  ExerciseDef(name: 'Low-to-High Cable Fly', category: 'Chest', equipment: Equipment.cableMachine, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=eQ_NBB6OBH4'),
  ExerciseDef(name: 'Svend Press', category: 'Chest', equipment: Equipment.other, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=cIoUZOnypS8'),
  ExerciseDef(name: 'Dumbbell Pullover', category: 'Chest', equipment: Equipment.dumbbell, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=moKuOuFNBDM'),
  ExerciseDef(name: 'Smith Machine Bench Press', category: 'Chest', equipment: Equipment.barbell, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=nFAQ35hmCqU'),

  // Back
  ExerciseDef(name: 'Pull-Up', category: 'Back', equipment: Equipment.bodyweight, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=TMnxKjdYcME'),
  ExerciseDef(name: 'Chin-Up', category: 'Back', equipment: Equipment.bodyweight, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=XlcTbrnJaAo'),
  ExerciseDef(name: 'Lat Pulldown', category: 'Back', equipment: Equipment.cableMachine, movement: MovementBadge.pulldown, videoUrl: 'https://www.youtube.com/watch?v=6MLs17iyK9I'),
  ExerciseDef(name: 'Barbell Row', category: 'Back', equipment: Equipment.barbell, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=JxzD2CfAkeg'),
  ExerciseDef(name: 'Dumbbell Row', category: 'Back', equipment: Equipment.dumbbell, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=nMFCMNKnLgQ'),
  ExerciseDef(name: 'T-Bar Row', category: 'Back', equipment: Equipment.barbell, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=SbZycT7Eq58'),
  ExerciseDef(name: 'Seated Cable Row', category: 'Back', equipment: Equipment.cableMachine, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=7BkgqzC6WsM'),
  ExerciseDef(name: 'Face Pull', category: 'Back', equipment: Equipment.cableMachine, movement: MovementBadge.pulldown, videoUrl: 'https://www.youtube.com/watch?v=0Po47vvj9g4'),
  ExerciseDef(name: 'Shrugs', category: 'Back', equipment: Equipment.barbell, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=X26Ji1j9LWA'),
  ExerciseDef(name: 'Front Lever', category: 'Back', equipment: Equipment.bodyweight, movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=AGhb8V8M758'),
  ExerciseDef(name: 'Muscle-Up', category: 'Back', equipment: Equipment.bodyweight, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=vpPjY4BtJuI'),
  ExerciseDef(name: 'Straight-Arm Pulldown', category: 'Back', equipment: Equipment.cableMachine, movement: MovementBadge.pulldown, videoUrl: 'https://www.youtube.com/watch?v=duHQk2PxNos'),
  ExerciseDef(name: 'Chest-Supported Row', category: 'Back', equipment: Equipment.cableMachine, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=3EP5HpKtJG0'),
  ExerciseDef(name: 'Inverted Row', category: 'Back', equipment: Equipment.bodyweight, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=Fl0UMfdEzsE'),

  // Legs — includes the hip-hinge movements (deadlift variants, good morning,
  // rack pull, hyperextension): quad/hamstring/glute-dominant despite the
  // back/erector involvement, so they belong here rather than in Back.
  ExerciseDef(name: 'Back Squat', category: 'Legs', equipment: Equipment.barbell, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=8Kls95w2jFA'),
  ExerciseDef(name: 'Front Squat', category: 'Legs', equipment: Equipment.barbell, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=y7bKgHdvGrY'),
  ExerciseDef(name: 'Leg Press', category: 'Legs', equipment: Equipment.cableMachine, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=p5dCqF7wWUw'),
  ExerciseDef(name: 'Romanian Deadlift', category: 'Legs', equipment: Equipment.barbell, movement: MovementBadge.hipThrust, videoUrl: 'https://www.youtube.com/watch?v=Q5vwsJFwhyg'),
  ExerciseDef(name: 'Deadlift', category: 'Legs', equipment: Equipment.barbell, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=Y1IGeJEXpF4'),
  ExerciseDef(name: 'Sumo Deadlift', category: 'Legs', equipment: Equipment.barbell, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=cDlOSfu-zHY'),
  ExerciseDef(name: 'Good Morning', category: 'Legs', equipment: Equipment.barbell, movement: MovementBadge.hipThrust, videoUrl: 'https://www.youtube.com/watch?v=qxNuAQknYQI'),
  ExerciseDef(name: 'Rack Pull', category: 'Legs', equipment: Equipment.barbell, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=aAjN8zS7Idg'),
  ExerciseDef(name: 'Hyperextension', category: 'Legs', equipment: Equipment.bodyweight, movement: MovementBadge.hipThrust, videoUrl: 'https://www.youtube.com/watch?v=qtjJUWCnDyE'),
  ExerciseDef(name: 'Lunges', category: 'Legs', equipment: Equipment.bodyweight, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=-_270H-3Wrc'),
  ExerciseDef(name: 'Bulgarian Split Squat', category: 'Legs', equipment: Equipment.dumbbell, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=eNqdgtc1uiA'),
  ExerciseDef(name: 'Leg Extension', category: 'Legs', equipment: Equipment.cableMachine, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=2lvdnQg04PM'),
  ExerciseDef(name: 'Leg Curl', category: 'Legs', equipment: Equipment.cableMachine, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=hqI59xXChFk'),
  ExerciseDef(name: 'Calf Raise', category: 'Legs', equipment: Equipment.barbell, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=3UWi44yN-wM'),
  ExerciseDef(name: 'Hip Thrust', category: 'Legs', equipment: Equipment.barbell, movement: MovementBadge.hipThrust, videoUrl: 'https://www.youtube.com/watch?v=h0tCgXGkaSA'),
  ExerciseDef(name: 'Goblet Squat', category: 'Legs', equipment: Equipment.dumbbell, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=s64Ss68bABQ'),
  ExerciseDef(name: 'Walking Lunge', category: 'Legs', equipment: Equipment.bodyweight, movement: MovementBadge.carry, videoUrl: 'https://www.youtube.com/watch?v=_qSuiZ62vqI'),
  ExerciseDef(name: 'Box Squat', category: 'Legs', equipment: Equipment.barbell, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=j4Tu3rVThFM'),
  ExerciseDef(name: 'Nordic Hamstring Curl', category: 'Legs', equipment: Equipment.bodyweight, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=htyDuCI8cm8'),
  ExerciseDef(name: 'ATG Split Squat', category: 'Legs', equipment: Equipment.bodyweight, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=g6KrlrOq4mw'),
  ExerciseDef(name: 'Cossack Squat', category: 'Legs', equipment: Equipment.bodyweight, movement: MovementBadge.twist, videoUrl: 'https://www.youtube.com/watch?v=xD9xXao9NmU'),
  ExerciseDef(name: 'Pistol Squat', category: 'Legs', equipment: Equipment.bodyweight, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=F85WzNX3YPw'),
  ExerciseDef(name: 'Hack Squat', category: 'Legs', equipment: Equipment.cableMachine, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=-lAnEGH2blE'),
  ExerciseDef(name: 'Seated Calf Raise', category: 'Legs', equipment: Equipment.cableMachine, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=I1uQtobaNRQ'),
  ExerciseDef(name: 'Step-Up', category: 'Legs', equipment: Equipment.dumbbell, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=vs87hPGdnCc'),
  ExerciseDef(name: 'Sissy Squat', category: 'Legs', equipment: Equipment.bodyweight, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=AYN-U5nZieY'),
  ExerciseDef(name: 'Reverse Lunge', category: 'Legs', equipment: Equipment.dumbbell, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=GcYirgCLhnI'),
  ExerciseDef(name: 'Glute Bridge', category: 'Legs', equipment: Equipment.bodyweight, movement: MovementBadge.hipThrust, videoUrl: 'https://www.youtube.com/watch?v=nuapk_-Q2BI'),
  ExerciseDef(name: 'Hip Adduction Machine', category: 'Legs', equipment: Equipment.cableMachine, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=CjAVezAggkI'),
  ExerciseDef(name: 'Hip Abduction Machine', category: 'Legs', equipment: Equipment.cableMachine, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=OjI5OpV6IWA'),

  // Shoulders
  ExerciseDef(name: 'Overhead Press', category: 'Shoulders', equipment: Equipment.barbell, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=eNFXEEdfQp4'),
  ExerciseDef(name: 'Dumbbell Shoulder Press', category: 'Shoulders', equipment: Equipment.dumbbell, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=TcVgUCm-pyM'),
  ExerciseDef(name: 'Arnold Press', category: 'Shoulders', equipment: Equipment.dumbbell, movement: MovementBadge.rotationalPress, videoUrl: 'https://www.youtube.com/watch?v=6Z15_WdXmVw'),
  ExerciseDef(name: 'Lateral Raise', category: 'Shoulders', equipment: Equipment.dumbbell, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/shorts/NZsldrqqca8'),
  ExerciseDef(name: 'Front Raise', category: 'Shoulders', equipment: Equipment.dumbbell, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=CH9JzDStL3U'),
  ExerciseDef(name: 'Rear Delt Fly', category: 'Shoulders', equipment: Equipment.dumbbell, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=LsT-bR_zxLo'),
  ExerciseDef(name: 'Upright Row', category: 'Shoulders', equipment: Equipment.barbell, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=jaAV-rD45I0'),
  ExerciseDef(name: 'Cable Lateral Raise', category: 'Shoulders', equipment: Equipment.cableMachine, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=qitQHqNZbeM'),
  ExerciseDef(name: 'Handstand Push-Up', category: 'Shoulders', equipment: Equipment.bodyweight, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=h0HjqYRlXYg'),
  ExerciseDef(name: 'Handstand Hold', category: 'Shoulders', equipment: Equipment.bodyweight, movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=2WGIWkgnY_s'),
  ExerciseDef(name: 'Machine Shoulder Press', category: 'Shoulders', equipment: Equipment.cableMachine, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=BAZkFGeUy5U'),
  ExerciseDef(name: 'Cable Front Raise', category: 'Shoulders', equipment: Equipment.cableMachine, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=P3vBVjyF1nk'),
  ExerciseDef(name: 'Reverse Pec Deck', category: 'Shoulders', equipment: Equipment.cableMachine, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=e4dJ1QoxUtI'),

  // Biceps — split out from the old combined "Arms" category so biceps and
  // triceps work are separately browsable/suggested instead of lumped
  // together.
  ExerciseDef(name: 'Barbell Curl', category: 'Biceps', equipment: Equipment.barbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=JJB8XgKltA8'),
  ExerciseDef(name: 'Dumbbell Curl', category: 'Biceps', equipment: Equipment.dumbbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=XE_pHwbst04'),
  ExerciseDef(name: 'Hammer Curl', category: 'Biceps', equipment: Equipment.dumbbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=BRVDS6HVR9Q'),
  ExerciseDef(name: 'Preacher Curl', category: 'Biceps', equipment: Equipment.dumbbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=gSsEC9O6NYU'),
  ExerciseDef(name: 'Barbell Preacher Curl', category: 'Biceps', equipment: Equipment.barbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=jilTTmyEoYY'),
  ExerciseDef(name: 'Concentration Curl', category: 'Biceps', equipment: Equipment.dumbbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=8KySC0rUgpQ'),
  ExerciseDef(name: 'Cable Curl', category: 'Biceps', equipment: Equipment.cableMachine, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=NFzTWp2qpiE'),
  ExerciseDef(name: 'Spider Curl', category: 'Biceps', equipment: Equipment.dumbbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=CITtSuda0Fg'),
  ExerciseDef(name: 'EZ-Bar Curl', category: 'Biceps', equipment: Equipment.barbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=SDFZBaJcTsU'),
  ExerciseDef(name: 'Reverse Curl', category: 'Biceps', equipment: Equipment.barbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=pXx38ZWRYjo'),
  ExerciseDef(name: 'Incline Dumbbell Curl', category: 'Biceps', equipment: Equipment.dumbbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=rAx_tf13V5k'),
  ExerciseDef(name: 'Drag Curl', category: 'Biceps', equipment: Equipment.barbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=K1baXRg-OG8'),
  ExerciseDef(name: 'Cross-Body Hammer Curl', category: 'Biceps', equipment: Equipment.dumbbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=7MrzVaPM0Uw'),
  ExerciseDef(name: 'Cable Rope Hammer Curl', category: 'Biceps', equipment: Equipment.cableMachine, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=VY4walmoM-I'),
  ExerciseDef(name: '21s', category: 'Biceps', equipment: Equipment.dumbbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=G3V5mlQAsts'),

  // Triceps
  ExerciseDef(name: 'Tricep Pushdown', category: 'Triceps', equipment: Equipment.cableMachine, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=qHDrQglWgS4'),
  ExerciseDef(name: 'Skull Crusher', category: 'Triceps', equipment: Equipment.barbell, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=tj81tVq3wLo'),
  ExerciseDef(name: 'Overhead Tricep Extension', category: 'Triceps', equipment: Equipment.dumbbell, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=DZgpCf5alfI'),
  ExerciseDef(name: 'Close-Grip Bench Press', category: 'Triceps', equipment: Equipment.barbell, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=UYJsFzqdgK4'),
  ExerciseDef(name: 'Dips', category: 'Triceps', equipment: Equipment.bodyweight, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=T1L4smOP0L8'),
  ExerciseDef(name: 'Diamond Push-Up', category: 'Triceps', equipment: Equipment.bodyweight, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=_6AvEX9-k8E'),
  ExerciseDef(name: 'Cable Overhead Tricep Extension', category: 'Triceps', equipment: Equipment.cableMachine, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=8WC7rIOkhi0'),
  ExerciseDef(name: 'Bench Dip', category: 'Triceps', equipment: Equipment.bodyweight, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=0326dy_-CzM'),
  ExerciseDef(name: 'Dumbbell Tricep Kickback', category: 'Triceps', equipment: Equipment.dumbbell, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=6SS6K3lAwZ8'),
  ExerciseDef(name: 'JM Press', category: 'Triceps', equipment: Equipment.dumbbell, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=FjkZpK8JhO8'),
  ExerciseDef(name: 'Tate Press', category: 'Triceps', equipment: Equipment.dumbbell, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=c86r5KVF7Xo'),
  ExerciseDef(name: 'Single Arm Cable Tricep Pushdown', category: 'Triceps', equipment: Equipment.cableMachine, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=oxXEsQgIUrM', unilateral: true),
  // No verified video sourced yet for these two — leave videoUrl unset
  // rather than guess one; see EXERCISE_VIDEO_REGISTRY.md convention above.
  ExerciseDef(name: 'Single Arm Tricep Extension', category: 'Triceps', equipment: Equipment.dumbbell, movement: MovementBadge.extension, unilateral: true),
  ExerciseDef(name: 'Single Arm Overhead Tricep Extension', category: 'Triceps', equipment: Equipment.dumbbell, movement: MovementBadge.extension, unilateral: true),

  // Forearms — wrist flexors/extensors and grip work, split out from Arms
  // since it's a distinct enough training focus (and previously had zero
  // dedicated exercises in the library).
  ExerciseDef(name: 'Barbell Wrist Curl', category: 'Forearms', equipment: Equipment.barbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=SqwIBiru46w'),
  ExerciseDef(name: 'Barbell Reverse Wrist Curl', category: 'Forearms', equipment: Equipment.barbell, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=SfENsl5klVA'),
  ExerciseDef(name: 'Dumbbell Wrist Curl', category: 'Forearms', equipment: Equipment.dumbbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=VGkF2NTtao0'),
  ExerciseDef(name: 'Behind-the-Back Barbell Wrist Curl', category: 'Forearms', equipment: Equipment.barbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=BhnIBEZxseo'),
  ExerciseDef(name: 'Cable Wrist Curl', category: 'Forearms', equipment: Equipment.cableMachine, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=WVAaKJvToe0'),
  ExerciseDef(name: 'Cable Reverse Wrist Curl', category: 'Forearms', equipment: Equipment.cableMachine, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=N-BdFkvrsek'),
  ExerciseDef(name: 'Zottman Curl', category: 'Forearms', equipment: Equipment.dumbbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=KhXiqxGxu1s'),
  ExerciseDef(name: 'Barbell Finger Curl', category: 'Forearms', equipment: Equipment.barbell, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=mp61xNRZcrk'),
  ExerciseDef(name: 'Wrist Roller', category: 'Forearms', equipment: Equipment.other, movement: MovementBadge.roll, videoUrl: 'https://www.youtube.com/watch?v=VPFQSgAiXco'),
  ExerciseDef(name: 'Plate Pinch', category: 'Forearms', equipment: Equipment.other, movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=LARw21BBiDk'),
  ExerciseDef(name: 'Hand Gripper', category: 'Forearms', equipment: Equipment.other, movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=DZpwd6E2yi0'),
  ExerciseDef(name: 'Dead Hang', category: 'Forearms', equipment: Equipment.bodyweight, movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=3i2kPN5w3Eg'),

  // Core
  ExerciseDef(name: 'Plank', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=sI-MNJTbf7U'),
  ExerciseDef(name: 'Side Plank', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.twist, videoUrl: 'https://www.youtube.com/watch?v=2aGunzN5YWA'),
  ExerciseDef(name: 'Crunch', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=NnVhqMQRvmM'),
  ExerciseDef(name: 'Sit-Up', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=pCX65Mtc_Kk'),
  ExerciseDef(name: 'Hanging Leg Raise', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=Pr1ieGZ5atk'),
  ExerciseDef(name: 'Russian Twist', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.twist, videoUrl: 'https://www.youtube.com/playlist?list=PLYV0ceqk2LUbs4VO9u8NvwMoMXtr9QQlu'),
  ExerciseDef(name: 'Cable Crunch', category: 'Core', equipment: Equipment.cableMachine, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=0KEP6A1deBE'),
  ExerciseDef(name: 'Ab Wheel Rollout', category: 'Core', equipment: Equipment.other, movement: MovementBadge.roll, videoUrl: 'https://www.youtube.com/watch?v=vqgqHqHDnmk'),
  ExerciseDef(name: 'Mountain Climber', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.carry, videoUrl: 'https://www.youtube.com/watch?v=ixxk9Qfn61o'),
  ExerciseDef(name: 'Bicycle Crunch', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.twist, videoUrl: 'https://www.youtube.com/watch?v=z2GXKmhXYl8'),
  ExerciseDef(name: 'Dead Bug', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=bxn9FBrt4-A'),
  ExerciseDef(name: 'Bird Dog', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=SkkRnTWelsI'),
  ExerciseDef(name: 'Pallof Press', category: 'Core', equipment: Equipment.cableMachine, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=_2xWmYNnFS8'),
  ExerciseDef(name: 'Hollow Body Hold', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=0yPin8hSc8o'),
  ExerciseDef(name: 'L-Sit', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=H_iZG5-L_KI'),
  ExerciseDef(name: 'Cable Woodchopper', category: 'Core', equipment: Equipment.cableMachine, movement: MovementBadge.twist, videoUrl: 'https://www.youtube.com/watch?v=Gwcf4TOj1hc'),
  ExerciseDef(name: 'Weighted Sit-Up', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=D_pSUxAQJ_s'),
  ExerciseDef(name: 'Toes to Bar', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=DVMrILiX_oc'),
  ExerciseDef(name: 'V-Up', category: 'Core', equipment: Equipment.bodyweight, movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=DfVArP2V6kg'),

  // Cardio
  ExerciseDef(name: 'Running', category: 'Cardio', icon: Icons.directions_run, videoUrl: 'https://m.youtube.com/shorts/5lLmItYTTzw'),
  ExerciseDef(name: 'Cycling', category: 'Cardio', icon: Icons.directions_bike, videoUrl: 'https://www.youtube.com/watch?v=jSEsIZ9ucgM'),
  ExerciseDef(name: 'Rowing Machine', category: 'Cardio', icon: Icons.rowing, videoUrl: 'https://www.youtube.com/watch?v=gvM-WuRfbkY'),
  // No dedicated glyph for jump rope exists anywhere; the jump badge on the running icon is the honest compromise.
  ExerciseDef(name: 'Jump Rope', category: 'Cardio', icon: Icons.directions_run, movement: MovementBadge.jump, videoUrl: 'https://www.youtube.com/watch?v=s-8tbwbEZ68'),
  ExerciseDef(name: 'Elliptical', category: 'Cardio', icon: Icons.directions_walk, videoUrl: 'https://www.youtube.com/watch?v=RakIFxUmSpA'),
  ExerciseDef(name: 'Stair Climber', category: 'Cardio', icon: Icons.stairs, videoUrl: 'https://www.youtube.com/watch?v=6eMPlQ95gXI'),
  ExerciseDef(name: 'Swimming', category: 'Cardio', icon: Icons.pool, videoUrl: 'https://www.youtube.com/watch?v=uiI6Z_0Q2Io'),

  // Pilates — badges differentiate by movement pattern even though every move is bodyweight + a category-default base icon.
  ExerciseDef(name: 'The Hundred', category: 'Pilates', movement: MovementBadge.hold, videoUrl: 'https://www.blogilates.com/videos/the-100-workout-pop-pilates/'),
  ExerciseDef(name: 'Roll-Up', category: 'Pilates', movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=pjPdNE6RHsk'),
  ExerciseDef(name: 'Single Leg Circle', category: 'Pilates', movement: MovementBadge.twist, videoUrl: 'https://www.youtube.com/watch?v=pg4WRNkbnjA'),
  ExerciseDef(name: 'Rolling Like a Ball', category: 'Pilates', movement: MovementBadge.roll, videoUrl: 'https://www.youtube.com/watch?v=EfVURwxctv8'),
  ExerciseDef(name: 'Single Leg Stretch', category: 'Pilates', movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=TlkVjAOaKBo'),
  ExerciseDef(name: 'Double Leg Stretch', category: 'Pilates', movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=N-jZas9tMSU'),
  ExerciseDef(name: 'Spine Stretch Forward', category: 'Pilates', movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=W261gg5PnNE'),
  ExerciseDef(name: 'Saw', category: 'Pilates', movement: MovementBadge.twist, videoUrl: 'https://www.youtube.com/watch?v=1XcU-WsTcaU'),
  ExerciseDef(name: 'Swan', category: 'Pilates', movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=Ab4eTe2R8z4'),
  ExerciseDef(name: 'Side Kick Series', category: 'Pilates', movement: MovementBadge.raise, videoUrl: 'https://www.youtube.com/watch?v=dH2uHO-uEu8'),
  ExerciseDef(name: 'Teaser', category: 'Pilates', movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=xVwpoIlQZPA'),
  ExerciseDef(name: 'Pilates Plank', category: 'Pilates', movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=sI-MNJTbf7U'),
  ExerciseDef(name: 'Bridge', category: 'Pilates', movement: MovementBadge.hipThrust, videoUrl: 'https://www.youtube.com/watch?v=h0tCgXGkaSA'),

  // Full-length follow-along Pilates sessions — duration/video-based rather
  // than individual named moves; sourced directly from Lilly Sabri's public
  // YouTube channel (confirmed live, real video IDs, not fabricated).
  ExerciseDef(name: '5 Min Pilates Snatched Waist (Lilly Sabri)', category: 'Pilates', movement: MovementBadge.twist, videoUrl: 'https://www.youtube.com/watch?v=HGvGk0Uc4Vg'),
  ExerciseDef(name: 'Quick 5 Min Summer Abs (Lilly Sabri)', category: 'Pilates', movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=EA9PoMkTH7w'),
  ExerciseDef(name: '5 Min Tighter Core, No Equipment (Lilly Sabri)', category: 'Pilates', movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=TifFvu1KS_g'),
  ExerciseDef(name: '5 Min Hourglass Abs (Lilly Sabri)', category: 'Pilates', movement: MovementBadge.twist, videoUrl: 'https://www.youtube.com/watch?v=4CDnGlcQJ4E'),
  ExerciseDef(name: '20 Min Full Body Pilates Sculpt (Lilly Sabri)', category: 'Pilates', videoUrl: 'https://www.youtube.com/watch?v=b5AI97ZGY8k'),
  ExerciseDef(name: '20 Min Deep Core Routine (Lilly Sabri)', category: 'Pilates', movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=MoGVA1smALM'),

  // Yoga — badges differentiate flowing sequences (swing) from static holds.
  ExerciseDef(name: 'Cat-Cow', category: 'Yoga', movement: MovementBadge.swing, videoUrl: 'https://www.youtube.com/watch?v=y39PrKY_4JM'),
  ExerciseDef(name: 'Downward-Facing Dog', category: 'Yoga', movement: MovementBadge.hold, videoUrl: 'https://yogawithadriene.com/downward-facing-dog/'),
  ExerciseDef(name: 'Pigeon Pose', category: 'Yoga', movement: MovementBadge.hold, videoUrl: 'https://yogawithadriene.com/pigeon-pose/'),
  ExerciseDef(name: 'Warrior II', category: 'Yoga', movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=4Ejz7IgODlU'),
  ExerciseDef(name: 'Tree Pose', category: 'Yoga', movement: MovementBadge.hold, videoUrl: 'https://yogawithadriene.com/tree-pose/'),
  ExerciseDef(name: "Child's Pose", category: 'Yoga', movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=ESy8ujdrZrk'),
  ExerciseDef(name: 'Sun Salutation A', category: 'Yoga', movement: MovementBadge.swing, videoUrl: 'https://www.youtube.com/watch?v=WH6NzQ1v04w'),
  ExerciseDef(name: 'Sun Salutation B', category: 'Yoga', movement: MovementBadge.swing, videoUrl: 'https://yogawithadriene.com/sun-salutation-b-surya-namaskara-b/'),

  // Mobility — badges differentiate rotation drills from static holds from the one true "roll".
  ExerciseDef(name: '90/90 Hip Stretch', category: 'Mobility', movement: MovementBadge.twist, videoUrl: 'https://www.youtube.com/watch?v=nWBKgtVjIjE'),
  ExerciseDef(name: 'Couch Stretch', category: 'Mobility', movement: MovementBadge.hold, videoUrl: 'https://www.youtube.com/watch?v=fKXvcIooNGA'),
  ExerciseDef(name: "World's Greatest Stretch", category: 'Mobility', movement: MovementBadge.twist, videoUrl: 'https://www.youtube.com/watch?v=ExuOImbFFFY'),
  ExerciseDef(name: 'Jefferson Curl', category: 'Mobility', movement: MovementBadge.curl, videoUrl: 'https://www.youtube.com/watch?v=BGQ-1Uptah8'),
  ExerciseDef(name: 'Foam Rolling', category: 'Mobility', movement: MovementBadge.roll, videoUrl: 'https://www.youtube.com/watch?v=iJ-Z2TaIHMU'),
  ExerciseDef(name: 'Ankle Dorsiflexion Stretch', category: 'Mobility', movement: MovementBadge.extension, videoUrl: 'https://www.youtube.com/watch?v=SQVpp_rZ7Ko'),
  ExerciseDef(name: 'Thoracic Rotation', category: 'Mobility', movement: MovementBadge.twist, videoUrl: 'https://www.youtube.com/watch?v=5TdmVlQe64c'),
  ExerciseDef(name: 'Banded Shoulder Dislocates', category: 'Mobility', equipment: Equipment.band, movement: MovementBadge.swing, videoUrl: 'https://www.youtube.com/watch?v=7p-Ma0eksaY'),

  // Full Body
  ExerciseDef(name: 'Burpee', category: 'Full Body', equipment: Equipment.bodyweight, movement: MovementBadge.jump, videoUrl: 'https://www.youtube.com/watch?v=G2hv_NYhM-A'),
  ExerciseDef(name: 'Kettlebell Swing', category: 'Full Body', equipment: Equipment.kettlebell, movement: MovementBadge.swing, videoUrl: 'https://www.youtube.com/watch?v=PAhDt_0PjP4'),
  ExerciseDef(name: 'Kettlebell Clean', category: 'Full Body', equipment: Equipment.kettlebell, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=5kR3mhJYvFw'),
  ExerciseDef(name: 'Kettlebell Snatch', category: 'Full Body', equipment: Equipment.kettlebell, movement: MovementBadge.jump, videoUrl: 'https://www.youtube.com/watch?v=3ZO3DzqaKfs'),
  ExerciseDef(name: 'Clean and Jerk', category: 'Full Body', equipment: Equipment.barbell, movement: MovementBadge.jump, videoUrl: 'https://www.youtube.com/@CatalystAthletics'),
  ExerciseDef(name: 'Power Clean', category: 'Full Body', equipment: Equipment.barbell, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=ORGBFvyUwGs'),
  ExerciseDef(name: 'Snatch', category: 'Full Body', equipment: Equipment.barbell, movement: MovementBadge.jump, videoUrl: 'https://www.youtube.com/watch?v=lvs8GVCPLCU'),
  ExerciseDef(name: 'Farmers Carry', category: 'Full Body', equipment: Equipment.dumbbell, movement: MovementBadge.carry, videoUrl: 'https://www.strongfirst.com/community/threads/loaded-carries.7924/'),
  ExerciseDef(name: 'Thruster', category: 'Full Body', equipment: Equipment.barbell, movement: MovementBadge.rotationalPress, videoUrl: 'https://www.youtube.com/watch?v=tJP-fwf5ASA'),
  ExerciseDef(name: 'Turkish Get-Up', category: 'Full Body', equipment: Equipment.kettlebell, movement: MovementBadge.carry, videoUrl: 'https://www.youtube.com/watch?v=0bWRPC49-KI'),
  ExerciseDef(name: 'Box Jump', category: 'Full Body', equipment: Equipment.other, movement: MovementBadge.jump, videoUrl: 'https://www.youtube.com/watch?v=3INzGHuk23U'),
  ExerciseDef(name: 'Battle Ropes', category: 'Full Body', equipment: Equipment.other, movement: MovementBadge.swing, videoUrl: 'https://www.youtube.com/watch?v=pQb2xIGioyQ'),
  ExerciseDef(name: 'Sled Push', category: 'Full Body', equipment: Equipment.other, movement: MovementBadge.press, videoUrl: 'https://www.youtube.com/watch?v=YJbKlXj4WhI'),
  ExerciseDef(name: 'Sled Pull', category: 'Full Body', equipment: Equipment.other, movement: MovementBadge.pull, videoUrl: 'https://www.youtube.com/watch?v=t081dogLJsU'),
  ExerciseDef(name: 'Medicine Ball Slam', category: 'Full Body', equipment: Equipment.other, movement: MovementBadge.pulldown, videoUrl: 'https://www.youtube.com/watch?v=lsMGmkvzFsE'),
  ExerciseDef(name: 'Tire Flip', category: 'Full Body', equipment: Equipment.other, movement: MovementBadge.squat, videoUrl: 'https://www.youtube.com/watch?v=aIDjGG_xwHg'),
];
