import 'package:flutter/material.dart';

import '../core/streak/streak_calculator.dart';
import '../models/food_entry.dart';
import '../models/nutrition_goal.dart';
import '../models/weight_entry.dart';
import '../models/workout_session.dart';

enum MedalCategory { training, cardio, nutrition, consistency }

/// Cosmetic rarity tier — drives color in the UI only, never gates unlock
/// logic. Roughly: bronze = first-time/entry, silver = a solid mid goal,
/// gold = advanced, platinum = the hardest/rarest medals in the catalog.
enum MedalTier { bronze, silver, gold, platinum }

/// Everything a [MedalDef.progress] function can read — all of it already
/// loaded by the relevant repositories, so evaluating the whole catalog
/// never issues a query of its own.
class MedalContext {
  final List<WorkoutSession> sessions;
  final List<WeightEntry> weightEntries;
  final List<GoalHistoryEntry> goalHistory;
  final List<FoodEntry> nutritionEntries;

  const MedalContext({
    required this.sessions,
    required this.weightEntries,
    required this.goalHistory,
    required this.nutritionEntries,
  });
}

class MedalDef {
  final String id;
  final String title;
  final String description;
  final MedalCategory category;
  final IconData icon;
  final MedalTier tier;

  /// 0.0 (no progress) .. 1.0 (unlocked). Pure function of [MedalContext].
  final double Function(MedalContext ctx) progress;

  const MedalDef({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.tier,
    required this.progress,
  });
}

double _maxWeightKgFor(MedalContext ctx, Set<String> exerciseNames) {
  var max = 0.0;
  for (final session in ctx.sessions) {
    for (final exercise in session.exercises) {
      if (!exerciseNames.contains(exercise.exerciseName)) continue;
      for (final set in exercise.sets) {
        if (set.weightKg > max) max = set.weightKg;
      }
    }
  }
  return max;
}

bool _hasLoggedAny(MedalContext ctx, Set<String> exerciseNames) {
  for (final session in ctx.sessions) {
    for (final exercise in session.exercises) {
      if (exerciseNames.contains(exercise.exerciseName) && exercise.sets.isNotEmpty) return true;
    }
  }
  return false;
}

double _maxCardioDistanceKm(MedalContext ctx) {
  var max = 0.0;
  for (final session in ctx.sessions) {
    for (final exercise in session.exercises) {
      final distance = exercise.distanceKm;
      if (distance != null && distance > max) max = distance;
    }
  }
  return max;
}

/// Sum of every cardio session's distance, unlike [_maxCardioDistanceKm]
/// (that session's best) — feeds the lifetime "Road Warrior" medals.
double _lifetimeCardioKm(MedalContext ctx) {
  var total = 0.0;
  for (final session in ctx.sessions) {
    for (final exercise in session.exercises) {
      final distance = exercise.distanceKm;
      if (distance != null) total += distance;
    }
  }
  return total;
}

/// How many goals of [mode] (deficit = cut, surplus = bulk) the user has
/// completed — a weight entry landed at or past [GoalHistoryEntry.targetWeightKg]
/// in the goal's direction while that goal was the active one.
int _completedGoalCount(MedalContext ctx, GoalMode mode) {
  var count = 0;
  for (final entry in ctx.goalHistory) {
    if (entry.mode != mode || entry.targetWeightKg == null) continue;
    final windowEnd = entry.endedAt ?? DateTime.now();
    final reached = ctx.weightEntries.any((w) {
      if (w.date.isBefore(entry.startedAt) || w.date.isAfter(windowEnd)) return false;
      return mode == GoalMode.deficit
          ? w.weightKg <= entry.targetWeightKg!
          : w.weightKg >= entry.targetWeightKg!;
    });
    if (reached) count++;
  }
  return count;
}

int _totalWorkoutCount(MedalContext ctx) => ctx.sessions.length;

/// Current active-day streak, exactly like the home screen's streak badge —
/// same combination of workout + nutrition-logging days fed into the same
/// [computeStreak]. Intentionally non-monotonic: breaking a 25-day streak
/// drops this back toward 0, same as every other app's streak badge. Once a
/// streak medal is actually unlocked it stays unlocked forever via the
/// persisted `unlocked_medals` table, regardless of later breaks.
int _activeDayStreak(MedalContext ctx) => computeStreak([
      ...ctx.sessions.map((s) => s.date),
      ...ctx.nutritionEntries.map((e) => e.date),
    ]);

int _distinctLoggedDays(MedalContext ctx) {
  final days = ctx.nutritionEntries
      .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
      .toSet();
  return days.length;
}

double _bigThreeTotalKg(MedalContext ctx) =>
    _maxWeightKgFor(ctx, _benchNames) +
    _maxWeightKgFor(ctx, _squatNames) +
    _maxWeightKgFor(ctx, _deadliftNames);

/// The most total weight (sum of weight*reps across every set) moved in any
/// single session.
double _maxSessionVolumeKg(MedalContext ctx) {
  var max = 0.0;
  for (final session in ctx.sessions) {
    var volume = 0.0;
    for (final exercise in session.exercises) {
      for (final set in exercise.sets) {
        volume += set.weightKg * set.reps;
      }
    }
    if (volume > max) max = volume;
  }
  return max;
}

/// Lifetime count of "beat my own best" moments per exact exercise name —
/// mirrors the single-session `isNewPr` check in
/// `lib/core/training/workout_summary.dart`, but walks the whole history to
/// count every time it happened, not just the most recent session.
int _lifetimePrCount(MedalContext ctx) {
  final sorted = [...ctx.sessions]..sort((a, b) => a.date.compareTo(b.date));
  final bestByExercise = <String, double>{};
  var count = 0;
  for (final session in sorted) {
    for (final exercise in session.exercises) {
      if (exercise.sets.isEmpty) continue;
      final topWeight = exercise.sets.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);
      final best = bestByExercise[exercise.exerciseName];
      if (best == null) {
        bestByExercise[exercise.exerciseName] = topWeight;
      } else if (topWeight > best) {
        bestByExercise[exercise.exerciseName] = topWeight;
        count++;
      }
    }
  }
  return count;
}

bool _isMetaMedal(MedalDef m) => m.id == 'collector_half' || m.id == 'collector_all';

/// Fraction (0..1) of the catalog, excluding the collector medals
/// themselves, that's currently unlocked — feeds the two collector medals
/// below. Safe to reference [medalCatalog] here: this closure only runs
/// when a caller reads `.progress(ctx)` on an already-obtained [MedalDef],
/// which can't happen until the top-level `medalCatalog` list literal has
/// finished constructing.
double _otherMedalsProgressFraction(MedalContext ctx) {
  final others = medalCatalog.where((m) => !_isMetaMedal(m)).toList();
  if (others.isEmpty) return 0;
  final unlockedCount = others.where((m) => m.progress(ctx) >= 1.0).length;
  return unlockedCount / others.length;
}

// Grouped by movement pattern, not exact exercise name — it doesn't matter
// whether the user does Back Squat, Hack Squat, or Front Squat, they should
// all build toward the same "squat" medals. See docs comment on
// `medalCatalog` below.
const _benchNames = {
  'Barbell Bench Press', 'Incline Bench Press', 'Decline Bench Press',
  'Dumbbell Bench Press', 'Incline Dumbbell Press', 'Smith Machine Bench Press',
  'Close-Grip Bench Press',
};
const _squatNames = {
  'Back Squat', 'Front Squat', 'Goblet Squat', 'Box Squat', 'Hack Squat',
  'Pistol Squat', 'Sissy Squat', 'ATG Split Squat', 'Leg Press',
};
const _deadliftNames = {
  'Deadlift', 'Sumo Deadlift', 'Romanian Deadlift', 'Rack Pull',
};
const _hipThrustNames = {'Hip Thrust', 'Glute Bridge'};
const _armNames = {
  'Barbell Curl', 'Dumbbell Curl', 'Hammer Curl', 'Preacher Curl', 'Cable Curl',
  'EZ-Bar Curl', 'Concentration Curl', 'Spider Curl', 'Reverse Curl',
  'Tricep Pushdown', 'Skull Crusher', 'Overhead Tricep Extension',
  'Cable Overhead Tricep Extension', 'Single Arm Tricep Extension',
  'Single Arm Overhead Tricep Extension',
};
const _pressNames = {
  'Overhead Press', 'Dumbbell Shoulder Press', 'Arnold Press', 'Machine Shoulder Press',
};
const _pullNames = {
  'Pull-Up', 'Chin-Up', 'Lat Pulldown', 'Barbell Row', 'Dumbbell Row', 'T-Bar Row',
  'Seated Cable Row', 'Chest-Supported Row', 'Inverted Row',
};

MedalDef _thresholdMedal({
  required String id,
  required String title,
  required String description,
  required MedalCategory category,
  required IconData icon,
  required MedalTier tier,
  required double Function(MedalContext ctx) value,
  required double threshold,
}) {
  return MedalDef(
    id: id,
    title: title,
    description: description,
    category: category,
    icon: icon,
    tier: tier,
    progress: (ctx) => (value(ctx) / threshold).clamp(0, 1),
  );
}

MedalDef _liftMedal({
  required String id,
  required String title,
  required Set<String> names,
  required double thresholdKg,
  required MedalTier tier,
}) {
  return _thresholdMedal(
    id: id,
    title: title,
    description: '${thresholdKg.toStringAsFixed(0)}kg on $title',
    category: MedalCategory.training,
    icon: Icons.military_tech,
    tier: tier,
    value: (ctx) => _maxWeightKgFor(ctx, names),
    threshold: thresholdKg,
  );
}

MedalDef _firstLiftMedal({required String id, required String title, required Set<String> names}) {
  return MedalDef(
    id: id,
    title: 'First $title',
    description: 'Log your first $title (any variant)',
    category: MedalCategory.training,
    icon: Icons.emoji_events,
    tier: MedalTier.bronze,
    progress: (ctx) => _hasLoggedAny(ctx, names) ? 1.0 : 0.0,
  );
}

MedalDef _goalTierMedal({
  required String id,
  required GoalMode mode,
  required int tier,
  required MedalTier rarity,
}) {
  final noun = mode == GoalMode.deficit ? 'cut' : 'bulk';
  return MedalDef(
    id: id,
    title: '$tier $noun${tier == 1 ? '' : 's'} completed',
    description: 'Reach your goal weight on $tier separate ${noun}s',
    category: MedalCategory.nutrition,
    icon: Icons.emoji_events,
    tier: rarity,
    progress: (ctx) => (_completedGoalCount(ctx, mode) / tier).clamp(0, 1),
  );
}

MedalDef _streakMedal({
  required String id,
  required String title,
  required String description,
  required int days,
  required MedalTier tier,
}) {
  return _thresholdMedal(
    id: id,
    title: title,
    description: description,
    category: MedalCategory.consistency,
    icon: Icons.local_fire_department,
    tier: tier,
    value: (ctx) => _activeDayStreak(ctx).toDouble(),
    threshold: days.toDouble(),
  );
}

MedalDef _workoutCountMedal({
  required String id,
  required String title,
  required int count,
  required MedalTier tier,
}) {
  return _thresholdMedal(
    id: id,
    title: title,
    description: 'Log $count workouts',
    category: MedalCategory.consistency,
    icon: Icons.fitness_center,
    tier: tier,
    value: (ctx) => _totalWorkoutCount(ctx).toDouble(),
    threshold: count.toDouble(),
  );
}

MedalDef _loggedDaysMedal({
  required String id,
  required String title,
  required int days,
  required MedalTier tier,
}) {
  return _thresholdMedal(
    id: id,
    title: title,
    description: 'Log food on $days different days',
    category: MedalCategory.consistency,
    icon: Icons.calendar_month,
    tier: tier,
    value: (ctx) => _distinctLoggedDays(ctx).toDouble(),
    threshold: days.toDouble(),
  );
}

MedalDef _cardioLifetimeMedal({
  required String id,
  required double km,
  required MedalTier tier,
}) {
  return _thresholdMedal(
    id: id,
    title: 'Road Warrior (${km.toStringAsFixed(0)}km)',
    description: 'Cover ${km.toStringAsFixed(0)}km lifetime across all cardio sessions',
    category: MedalCategory.cardio,
    icon: Icons.directions_run,
    tier: tier,
    value: _lifetimeCardioKm,
    threshold: km,
  );
}

/// The full set of medals the app tracks. Data-driven so adding a new one
/// is just another entry here — nothing else needs to change.
final List<MedalDef> medalCatalog = [
  MedalDef(
    id: 'first_workout',
    title: 'First Workout',
    description: 'Log your first workout',
    category: MedalCategory.training,
    icon: Icons.emoji_events,
    tier: MedalTier.bronze,
    progress: (ctx) => ctx.sessions.isNotEmpty ? 1.0 : 0.0,
  ),
  _firstLiftMedal(id: 'first_bench', title: 'Bench Press', names: _benchNames),
  _firstLiftMedal(id: 'first_squat', title: 'Squat', names: _squatNames),
  _firstLiftMedal(id: 'first_deadlift', title: 'Deadlift', names: _deadliftNames),
  _firstLiftMedal(id: 'first_hip_thrust', title: 'Hip Thrust', names: _hipThrustNames),
  _firstLiftMedal(id: 'first_bicep_curl', title: 'Curl or Extension', names: _armNames),
  _firstLiftMedal(id: 'first_press', title: 'Overhead Press', names: _pressNames),
  _firstLiftMedal(id: 'first_pull', title: 'Row or Pull-Up', names: _pullNames),
  _liftMedal(id: 'bench_50kg', title: 'Bench Press', names: _benchNames, thresholdKg: 50, tier: MedalTier.silver),
  _liftMedal(id: 'bench_100kg', title: 'Bench Press', names: _benchNames, thresholdKg: 100, tier: MedalTier.gold),
  _liftMedal(id: 'squat_50kg', title: 'Squat', names: _squatNames, thresholdKg: 50, tier: MedalTier.silver),
  _liftMedal(id: 'squat_100kg', title: 'Squat', names: _squatNames, thresholdKg: 100, tier: MedalTier.gold),
  _liftMedal(id: 'deadlift_50kg', title: 'Deadlift', names: _deadliftNames, thresholdKg: 50, tier: MedalTier.silver),
  _liftMedal(id: 'deadlift_100kg', title: 'Deadlift', names: _deadliftNames, thresholdKg: 100, tier: MedalTier.gold),
  _liftMedal(id: 'hip_thrust_50kg', title: 'Hip Thrust', names: _hipThrustNames, thresholdKg: 50, tier: MedalTier.silver),
  _liftMedal(id: 'hip_thrust_100kg', title: 'Hip Thrust', names: _hipThrustNames, thresholdKg: 100, tier: MedalTier.gold),
  _liftMedal(id: 'press_40kg', title: 'Overhead Press', names: _pressNames, thresholdKg: 40, tier: MedalTier.silver),
  _liftMedal(id: 'press_80kg', title: 'Overhead Press', names: _pressNames, thresholdKg: 80, tier: MedalTier.gold),
  _liftMedal(id: 'row_40kg', title: 'Row', names: _pullNames, thresholdKg: 40, tier: MedalTier.silver),
  _liftMedal(id: 'row_80kg', title: 'Row', names: _pullNames, thresholdKg: 80, tier: MedalTier.gold),
  MedalDef(
    id: 'arms_25kg',
    title: 'Arms of Steel',
    description: '25kg on a curl or tricep extension (per arm, for single-arm exercises)',
    category: MedalCategory.training,
    icon: Icons.military_tech,
    tier: MedalTier.gold,
    progress: (ctx) => (_maxWeightKgFor(ctx, _armNames) / 25).clamp(0, 1),
  ),
  _thresholdMedal(
    id: 'big_three_150',
    title: 'Powerlifter (150kg total)',
    description: 'Bench + Squat + Deadlift combined ≥ 150kg',
    category: MedalCategory.training,
    icon: Icons.military_tech,
    tier: MedalTier.bronze,
    value: _bigThreeTotalKg,
    threshold: 150,
  ),
  _thresholdMedal(
    id: 'big_three_300',
    title: 'Powerlifter (300kg total)',
    description: 'Bench + Squat + Deadlift combined ≥ 300kg',
    category: MedalCategory.training,
    icon: Icons.military_tech,
    tier: MedalTier.silver,
    value: _bigThreeTotalKg,
    threshold: 300,
  ),
  _thresholdMedal(
    id: 'big_three_500',
    title: 'Powerlifter (500kg total)',
    description: 'Bench + Squat + Deadlift combined ≥ 500kg',
    category: MedalCategory.training,
    icon: Icons.military_tech,
    tier: MedalTier.platinum,
    value: _bigThreeTotalKg,
    threshold: 500,
  ),
  _thresholdMedal(
    id: 'volume_5000',
    title: 'Volume Warrior (5,000kg)',
    description: 'Move 5,000kg total weight in one session',
    category: MedalCategory.training,
    icon: Icons.military_tech,
    tier: MedalTier.silver,
    value: _maxSessionVolumeKg,
    threshold: 5000,
  ),
  _thresholdMedal(
    id: 'volume_10000',
    title: 'Volume Warrior (10,000kg)',
    description: 'Move 10,000kg total weight in one session',
    category: MedalCategory.training,
    icon: Icons.military_tech,
    tier: MedalTier.gold,
    value: _maxSessionVolumeKg,
    threshold: 10000,
  ),
  _thresholdMedal(
    id: 'pr_count_5',
    title: 'PR Machine',
    description: 'Set 5 lifetime personal records',
    category: MedalCategory.training,
    icon: Icons.military_tech,
    tier: MedalTier.bronze,
    value: (ctx) => _lifetimePrCount(ctx).toDouble(),
    threshold: 5,
  ),
  _thresholdMedal(
    id: 'pr_count_25',
    title: 'Record Breaker',
    description: 'Set 25 lifetime personal records',
    category: MedalCategory.training,
    icon: Icons.military_tech,
    tier: MedalTier.gold,
    value: (ctx) => _lifetimePrCount(ctx).toDouble(),
    threshold: 25,
  ),
  MedalDef(
    id: 'cardio_5k',
    title: '5K',
    description: 'Run, ride, or swim 5km in one session',
    category: MedalCategory.cardio,
    icon: Icons.directions_run,
    tier: MedalTier.bronze,
    progress: (ctx) => (_maxCardioDistanceKm(ctx) / 5).clamp(0, 1),
  ),
  MedalDef(
    id: 'cardio_10k',
    title: '10K',
    description: 'Run, ride, or swim 10km in one session',
    category: MedalCategory.cardio,
    icon: Icons.directions_run,
    tier: MedalTier.silver,
    progress: (ctx) => (_maxCardioDistanceKm(ctx) / 10).clamp(0, 1),
  ),
  MedalDef(
    id: 'cardio_half_marathon',
    title: 'Half Marathon',
    description: 'Run, ride, or swim 21.1km in one session',
    category: MedalCategory.cardio,
    icon: Icons.directions_run,
    tier: MedalTier.gold,
    progress: (ctx) => (_maxCardioDistanceKm(ctx) / 21.1).clamp(0, 1),
  ),
  MedalDef(
    id: 'cardio_marathon',
    title: 'Marathon',
    description: 'Run, ride, or swim 42.2km in one session',
    category: MedalCategory.cardio,
    icon: Icons.directions_run,
    tier: MedalTier.platinum,
    progress: (ctx) => (_maxCardioDistanceKm(ctx) / 42.2).clamp(0, 1),
  ),
  _cardioLifetimeMedal(id: 'cardio_lifetime_50', km: 50, tier: MedalTier.bronze),
  _cardioLifetimeMedal(id: 'cardio_lifetime_200', km: 200, tier: MedalTier.silver),
  _cardioLifetimeMedal(id: 'cardio_lifetime_500', km: 500, tier: MedalTier.gold),
  MedalDef(
    id: 'first_meal_logged',
    title: 'First Meal Logged',
    description: 'Log your first meal',
    category: MedalCategory.nutrition,
    icon: Icons.restaurant,
    tier: MedalTier.bronze,
    progress: (ctx) => ctx.nutritionEntries.isNotEmpty ? 1.0 : 0.0,
  ),
  _goalTierMedal(id: 'cut_1', mode: GoalMode.deficit, tier: 1, rarity: MedalTier.bronze),
  _goalTierMedal(id: 'cut_3', mode: GoalMode.deficit, tier: 3, rarity: MedalTier.silver),
  _goalTierMedal(id: 'cut_5', mode: GoalMode.deficit, tier: 5, rarity: MedalTier.gold),
  _goalTierMedal(id: 'cut_10', mode: GoalMode.deficit, tier: 10, rarity: MedalTier.platinum),
  _goalTierMedal(id: 'bulk_1', mode: GoalMode.surplus, tier: 1, rarity: MedalTier.bronze),
  _goalTierMedal(id: 'bulk_3', mode: GoalMode.surplus, tier: 3, rarity: MedalTier.silver),
  _goalTierMedal(id: 'bulk_5', mode: GoalMode.surplus, tier: 5, rarity: MedalTier.gold),
  _goalTierMedal(id: 'bulk_10', mode: GoalMode.surplus, tier: 10, rarity: MedalTier.platinum),
  _streakMedal(id: 'streak_7', title: 'Week Warrior', description: 'Log a workout or meal 7 days in a row', days: 7, tier: MedalTier.bronze),
  _streakMedal(id: 'streak_30', title: 'Month Strong', description: '30-day active streak', days: 30, tier: MedalTier.silver),
  _streakMedal(id: 'streak_100', title: 'Centurion', description: '100-day active streak', days: 100, tier: MedalTier.gold),
  _streakMedal(id: 'streak_365', title: 'Unstoppable', description: '365-day active streak', days: 365, tier: MedalTier.platinum),
  _workoutCountMedal(id: 'workouts_10', title: 'Getting Started', count: 10, tier: MedalTier.bronze),
  _workoutCountMedal(id: 'workouts_50', title: 'Half Century', count: 50, tier: MedalTier.silver),
  _workoutCountMedal(id: 'workouts_100', title: 'Triple Digits', count: 100, tier: MedalTier.gold),
  _workoutCountMedal(id: 'workouts_250', title: 'Iron Devotion', count: 250, tier: MedalTier.platinum),
  _loggedDaysMedal(id: 'logged_days_30', title: 'Dialed In', days: 30, tier: MedalTier.bronze),
  _loggedDaysMedal(id: 'logged_days_100', title: 'Nutrition Nerd', days: 100, tier: MedalTier.silver),
  MedalDef(
    id: 'collector_half',
    title: 'Halfway There',
    description: 'Unlock 50% of all other medals',
    category: MedalCategory.consistency,
    icon: Icons.workspace_premium,
    tier: MedalTier.silver,
    progress: (ctx) => (_otherMedalsProgressFraction(ctx) / 0.5).clamp(0, 1),
  ),
  MedalDef(
    id: 'collector_all',
    title: 'Completionist',
    description: 'Unlock every other medal',
    category: MedalCategory.consistency,
    icon: Icons.workspace_premium,
    tier: MedalTier.platinum,
    progress: (ctx) => _otherMedalsProgressFraction(ctx),
  ),
];
