import '../../models/user_profile.dart';

class ActivityLevel {
  final double multiplier;
  final String label;

  const ActivityLevel({required this.multiplier, required this.label});
}

/// The same 6-tier activity scale used everywhere in this file, but as a
/// self-reportable enum rather than a derived [ActivityLevel] — lets a
/// brand-new user (with no workout history yet to estimate exercise from)
/// state their activity
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

  /// BMR multiplier for everything *except* structured exercise: digesting
  /// food plus ordinary daily movement. 1.2 is the standard "sedentary"
  /// factor every Mifflin-St Jeor calculator uses; the other two follow the
  /// usual light/moderate physical-activity-level steps for jobs that keep
  /// you moving all day.
  double get neatFactor {
    switch (this) {
      case JobActivityLevel.desk:
        return 1.2;
      case JobActivityLevel.onFeet:
        return 1.35;
      case JobActivityLevel.physical:
        return 1.55;
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

  /// Average MET across a whole session (rest between sets included), from
  /// the Compendium of Physical Activities: light resistance/circuit work
  /// ~3.5, a typical moderate lifting session ~5, hard lifting or steady
  /// cardio ~7.
  double get met {
    switch (this) {
      case ExerciseIntensity.light:
        return 3.5;
      case ExerciseIntensity.moderate:
        return 5.0;
      case ExerciseIntensity.hard:
        return 7.0;
    }
  }
}

/// Extra calories one exercise session burns *on top of* resting — (MET - 1)
/// because the resting 1 MET is already inside BMR. 1 MET ≈ 1 kcal per kg
/// per hour.
double exerciseSessionKcal({
  required double weightKg,
  required int minutes,
  required ExerciseIntensity intensity,
}) {
  return (intensity.met - 1) * weightKg * (minutes / 60);
}

/// The richer activity questionnaire behind the "Use my activity answers"
/// setting — daily job activity plus exercise days/week, how long a session
/// is, and how hard.
///
/// An earlier version snapped these answers onto the 6-tier activity table
/// (1.2 ... 1.9). That broke down for exactly the people who answer this:
/// "7 days a week" always landed on the top "very intense exercise daily"
/// 1.9 tier, overestimating a desk worker who lifts for an hour a day by
/// roughly 900 kcal. Adding up job baseline + actual exercise energy
/// instead is how dedicated TDEE calculators do it and doesn't have cliffs
/// between tiers.
class PreciseActivityInput {
  static const defaultMinutesPerSession = 60;

  final JobActivityLevel job;
  final int exerciseDaysPerWeek;
  final ExerciseIntensity intensity;
  final int minutesPerSession;

  const PreciseActivityInput({
    required this.job,
    required this.exerciseDaysPerWeek,
    required this.intensity,
    this.minutesPerSession = defaultMinutesPerSession,
  });

  /// Average exercise calories per day across the week.
  double exerciseKcalPerDay(double weightKg) {
    final perSession = exerciseSessionKcal(
      weightKg: weightKg,
      minutes: minutesPerSession,
      intensity: intensity,
    );
    return perSession * exerciseDaysPerWeek / 7;
  }

  double tdee({required double bmr, required double weightKg}) =>
      bmr * job.neatFactor + exerciseKcalPerDay(weightKg);

  String get summary {
    final days = exerciseDaysPerWeek == 1 ? '1 day' : '$exerciseDaysPerWeek days';
    return '${job.label} · $days/week × $minutesPerSession min, ${intensity.label.toLowerCase()}';
  }
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
}
