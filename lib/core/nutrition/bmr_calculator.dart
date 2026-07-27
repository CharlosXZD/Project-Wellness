import '../../models/user_profile.dart';

class ActivityLevel {
  final double multiplier;
  final String label;

  const ActivityLevel({required this.multiplier, required this.label});
}

/// The same 6-tier activity scale used everywhere in this file, but as a
/// self-reportable enum rather than a derived [ActivityLevel] — lets a
/// brand-new user (with no workout history yet for
/// [BmrCalculator.activityFromWeeklySessions] to read) state their activity
/// level directly at onboarding. Persisted on [UserProfile.initialActivityLevel].
///
/// Matches the 6-row "daily calories needed" table calculator.net's BMR
/// calculator uses (not the older, coarser 5-tier Harris-Benedict scale this
/// enum used before) — [fourToFive] is the tier that table has and the old
/// 5-tier scale didn't. Existing member names (`sedentary`/`light`/
/// `moderate`/`active`/`extreme`) are kept as-is even though a couple of
/// labels/multipliers shifted meaning slightly, so profiles that already
/// persisted one of those names (`UserProfile.initialActivityLevel` stores
/// the enum's `.name`) keep resolving correctly.
enum SelfReportedActivityLevel { sedentary, light, fourToFive, moderate, active, extreme }

extension SelfReportedActivityLevelValue on SelfReportedActivityLevel {
  ActivityLevel get activityLevel {
    switch (this) {
      case SelfReportedActivityLevel.sedentary:
        return const ActivityLevel(multiplier: 1.2, label: 'Sedentary');
      case SelfReportedActivityLevel.light:
        return const ActivityLevel(multiplier: 1.375, label: 'Exercise 1-3x/week');
      case SelfReportedActivityLevel.fourToFive:
        return const ActivityLevel(multiplier: 1.465, label: 'Exercise 4-5x/week');
      case SelfReportedActivityLevel.moderate:
        return const ActivityLevel(multiplier: 1.55, label: 'Daily, or intense exercise 3-4x/week');
      case SelfReportedActivityLevel.active:
        return const ActivityLevel(multiplier: 1.725, label: 'Intense exercise 6-7x/week');
      case SelfReportedActivityLevel.extreme:
        return const ActivityLevel(multiplier: 1.9, label: 'Very intense exercise daily');
    }
  }

  String get label => activityLevel.label;

  String get description {
    switch (this) {
      case SelfReportedActivityLevel.sedentary:
        return 'Little to no exercise, desk-based day';
      case SelfReportedActivityLevel.light:
        return 'Light exercise 1-3 days a week';
      case SelfReportedActivityLevel.fourToFive:
        return 'Moderate exercise 4-5 days a week';
      case SelfReportedActivityLevel.moderate:
        return 'Exercise every day, or intense exercise 3-4 days a week';
      case SelfReportedActivityLevel.active:
        return 'Intense exercise 6-7 days a week';
      case SelfReportedActivityLevel.extreme:
        return 'Very intense exercise daily, or a physically demanding job';
    }
  }
}

/// Whether a very-active self-report is plausible given no logged workouts
/// — used to drive the "are we missing your workouts?" nudge.
extension SelfReportedActivityLevelNudge on SelfReportedActivityLevel {
  bool get isHighActivity =>
      this == SelfReportedActivityLevel.active || this == SelfReportedActivityLevel.extreme;
}

/// Day-to-day job/life activity — a NEAT (non-exercise activity
/// thermogenesis) signal that's independent of logged workouts, used by
/// [PreciseActivityInput].
enum JobActivityLevel { desk, onFeet, physical }

extension JobActivityLevelValue on JobActivityLevel {
  String get label {
    switch (this) {
      case JobActivityLevel.desk:
        return 'Desk job';
      case JobActivityLevel.onFeet:
        return 'On my feet most of the day';
      case JobActivityLevel.physical:
        return 'Physically demanding job';
    }
  }

  /// How many tiers a demanding job alone nudges the result up by — small
  /// on purpose. This is a secondary modifier on top of the exercise-driven
  /// base tier below, not the dominant factor: a desk job shouldn't be able
  /// to cap someone who trains hard 6 days a week at a low tier.
  int get _tierBump {
    switch (this) {
      case JobActivityLevel.desk:
        return 0;
      case JobActivityLevel.onFeet:
        return 0;
      case JobActivityLevel.physical:
        return 1;
    }
  }
}

enum ExerciseIntensity { light, moderate, hard }

extension ExerciseIntensityValue on ExerciseIntensity {
  String get label {
    switch (this) {
      case ExerciseIntensity.light:
        return 'Light';
      case ExerciseIntensity.moderate:
        return 'Moderate';
      case ExerciseIntensity.hard:
        return 'Hard';
    }
  }

  /// How many tiers this intensity nudges the exercise-days base tier by.
  int get _tierNudge {
    switch (this) {
      case ExerciseIntensity.light:
        return -1;
      case ExerciseIntensity.moderate:
        return 0;
      case ExerciseIntensity.hard:
        return 1;
    }
  }
}

/// The richer activity questionnaire behind the opt-in "Precise calorie
/// tracking" setting — daily job activity plus structured exercise
/// days/week and typical intensity, in place of just guessing from this
/// app's own workout-session count. A stronger signal than the blunt
/// session-count heuristic, so [BmrCalculator.calculate] also drops the
/// target-calorie band entirely (a single number, not a range) when this is
/// supplied.
class PreciseActivityInput {
  final JobActivityLevel job;
  final int exerciseDaysPerWeek;
  final ExerciseIntensity intensity;

  const PreciseActivityInput({
    required this.job,
    required this.exerciseDaysPerWeek,
    required this.intensity,
  });

  /// Picks one of [SelfReportedActivityLevel]'s six tiers directly — the
  /// tiers are frequency-branded ("Exercise 1-3x/week", "Intense 6-7x/week",
  /// etc.), so [exerciseDaysPerWeek] decides the base tier the same way
  /// [BmrCalculator.activityFromWeeklySessions] does, [intensity] nudges it
  /// one tier up or down, and [job]'s NEAT baseline only nudges it up by at
  /// most one tier on top of that.
  ///
  /// An earlier version instead summed a job baseline (1.2-1.5) with a
  /// small per-day exercise bump (0.02-0.05/day) into one continuous score
  /// and snapped *that* to the nearest tier — which let the job baseline
  /// dominate: a desk job (1.2) plus 6 days/week of moderate exercise
  /// (+0.21) only reached 1.41, snapping down to "Exercise 1-3x/week"
  /// despite 6 actual training days. Deciding from exercise days first
  /// avoids that.
  ActivityLevel toActivityLevel() {
    final tierIndex =
        (_baseTierIndexForDays(exerciseDaysPerWeek) + intensity._tierNudge + job._tierBump)
            .clamp(0, SelfReportedActivityLevel.values.length - 1);
    return SelfReportedActivityLevel.values[tierIndex].activityLevel;
  }

  /// Same day-count buckets as [BmrCalculator.activityFromWeeklySessions]
  /// (and so, like it, never lands on [SelfReportedActivityLevel.moderate]
  /// on its own — [intensity]'s nudge is what reaches that tier).
  static int _baseTierIndexForDays(int days) {
    if (days <= 0) return SelfReportedActivityLevel.sedentary.index;
    if (days <= 2) return SelfReportedActivityLevel.light.index;
    if (days <= 4) return SelfReportedActivityLevel.fourToFive.index;
    if (days <= 6) return SelfReportedActivityLevel.active.index;
    return SelfReportedActivityLevel.extreme.index;
  }
}

class BmrResult {
  final double bmr;
  final double tdeeLow;
  final double tdeeHigh;
  final ActivityLevel activity;

  const BmrResult({
    required this.bmr,
    required this.tdeeLow,
    required this.tdeeHigh,
    required this.activity,
  });
}

class BmrCalculator {
  /// Mifflin-St Jeor equation.
  static double bmr({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return sex == Sex.male ? base + 5 : base - 161;
  }

  /// This session-count guess can't tell "moderate but intense" (the
  /// [SelfReportedActivityLevel.moderate] tier) apart from a plain frequency
  /// count, so it only ever lands on the other five tiers — [moderate] is
  /// reachable through [PreciseActivityInput] or the onboarding self-report.
  static ActivityLevel activityFromWeeklySessions(int sessionsLast7Days) {
    if (sessionsLast7Days <= 0) return SelfReportedActivityLevel.sedentary.activityLevel;
    if (sessionsLast7Days <= 2) return SelfReportedActivityLevel.light.activityLevel;
    if (sessionsLast7Days <= 4) return SelfReportedActivityLevel.fourToFive.activityLevel;
    if (sessionsLast7Days <= 6) return SelfReportedActivityLevel.active.activityLevel;
    return SelfReportedActivityLevel.extreme.activityLevel;
  }

  /// Alternative to [activityFromWeeklySessions] when real step-count data
  /// is available (Apple Health / Health Connect) — standard step-count
  /// activity bands, generally a better signal than a workout-count guess
  /// since it also captures non-workout daily movement. Same caveat as
  /// [activityFromWeeklySessions]: never lands on [SelfReportedActivityLevel
  /// .moderate], since a step count alone can't distinguish that tier from a
  /// plain frequency-based one.
  static ActivityLevel activityFromHealthData({
    required int avgSteps,
    required double avgActiveEnergyKcal,
  }) {
    if (avgSteps < 5000) return SelfReportedActivityLevel.sedentary.activityLevel;
    if (avgSteps < 7500) return SelfReportedActivityLevel.light.activityLevel;
    if (avgSteps < 10000) return SelfReportedActivityLevel.fourToFive.activityLevel;
    if (avgSteps < 12500) return SelfReportedActivityLevel.active.activityLevel;
    return SelfReportedActivityLevel.extreme.activityLevel;
  }

  /// Ballpark TDEE range, the way most online calculators present
  /// maintenance calories rather than claiming false precision — +/- 150
  /// kcal normally, or an exact single number (no range) when
  /// [preciseActivity] is supplied, since at that point the answers have
  /// already picked one specific tier off the table rather than leaving
  /// room for a guess.
  ///
  /// Priority when multiple sources are available: [avgActiveEnergyKcal]
  /// (real device data) first, then [preciseActivity], then
  /// [overrideActivity] (health-derived activity tier, or a fallback like
  /// the user's self-reported onboarding answer — see
  /// `computeTargetCalories`), then the [sessionsLast7Days] heuristic.
  static BmrResult calculate({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
    required int sessionsLast7Days,
    ActivityLevel? overrideActivity,
    double? avgActiveEnergyKcal,
    PreciseActivityInput? preciseActivity,
  }) {
    final bmrValue = bmr(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age);

    final activity = overrideActivity ??
        preciseActivity?.toActivityLevel() ??
        activityFromWeeklySessions(sessionsLast7Days);

    final tdee = avgActiveEnergyKcal != null
        ? bmrValue * 1.2 + avgActiveEnergyKcal
        : bmrValue * activity.multiplier;

    final band = (avgActiveEnergyKcal == null && overrideActivity == null && preciseActivity != null)
        ? 0.0
        : 150.0;

    return BmrResult(
      bmr: bmrValue,
      tdeeLow: tdee - band,
      tdeeHigh: tdee + band,
      activity: activity,
    );
  }
}
