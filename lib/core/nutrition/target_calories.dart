import 'dart:math' as math;

import '../../models/food_entry.dart';
import '../../models/nutrition_goal.dart';
import '../../models/user_profile.dart';
import '../../models/weight_entry.dart';
import '../../models/workout_session.dart';
import '../health/health_service.dart';
import 'bmr_calculator.dart';

/// Energy in one kg of body-weight change — the standard ~7700 kcal/kg
/// (3500 kcal/lb) figure every weight-trend TDEE calculator uses.
const kcalPerKgBodyWeight = 7700.0;

/// Where the formula-side maintenance estimate came from, strongest signal
/// first. See [estimateFormulaTdee].
enum TdeeSource { healthData, activityAnswers, onboardingAnswer, workoutLog }

extension TdeeSourceLabel on TdeeSource {
  String get label {
    switch (this) {
      case TdeeSource.healthData:
        return 'From your Health activity data';
      case TdeeSource.activityAnswers:
        return 'From your activity answers';
      case TdeeSource.onboardingAnswer:
        return 'From the activity level you picked at sign-up';
      case TdeeSource.workoutLog:
        return 'From the workouts you log here';
    }
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The most recent logged weigh-in, falling back to the onboarding weight —
/// the one "current weight" every calorie number in the app uses.
double currentWeightKg(UserProfile profile, List<WeightEntry> weightEntries) {
  if (weightEntries.isEmpty) return profile.weightKg;
  var latest = weightEntries.first;
  for (final entry in weightEntries) {
    if (entry.date.isAfter(latest.date)) latest = entry;
  }
  return latest.weightKg;
}

// ---------------------------------------------------------------------------
// Formula side
// ---------------------------------------------------------------------------

class FormulaTdee {
  final double bmr;
  final double tdee;
  final TdeeSource source;

  /// One line describing the inputs, e.g. "Desk job · 7 days/week × 60 min,
  /// moderate" — shown under "How we calculated this".
  final String detail;

  const FormulaTdee({
    required this.bmr,
    required this.tdee,
    required this.source,
    required this.detail,
  });
}

/// A brand-new account has no in-app workout history yet, so a
/// workout-log-based guess would start everyone at "sedentary". While
/// that's still true (first ~2 weeks, essentially no sessions logged),
/// [UserProfile.initialActivityLevel] — asked once at onboarding — stands
/// in instead.
const _newAccountWindow = Duration(days: 14);

/// Typical session length from the user's own logged workouts — the median
/// (so a timer left running for 6 hours doesn't count as a 6-hour workout),
/// clamped to a sane 20-120 minutes.
int typicalLoggedSessionMinutes(List<WorkoutSession> sessions) {
  final durations = sessions
      .map((s) => s.durationMinutes)
      .whereType<int>()
      .where((m) => m >= 5)
      .toList()
    ..sort();
  if (durations.isEmpty) return PreciseActivityInput.defaultMinutesPerSession;
  return durations[durations.length ~/ 2].clamp(20, 120);
}

/// Maintenance calories from BMR plus an activity estimate — the classic
/// "TDEE calculator" number, before anything is learned from the user's own
/// logs. Priority: real Health active-energy data, then the user's activity
/// answers, then (new accounts only) the onboarding self-report, then the
/// workouts logged in this app over the last 4 weeks.
FormulaTdee estimateFormulaTdee({
  required UserProfile profile,
  required double weightKg,
  required List<WorkoutSession> sessions,
  HealthActivitySummary? health,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final bmr = BmrCalculator.bmr(
    sex: profile.sex!,
    weightKg: weightKg,
    heightCm: profile.heightCm,
    age: profile.age,
  );

  // Phone-only Health setups report almost no active energy (no gym
  // workouts, just walking), which would read as "sedentary" — only trust
  // it once it's clearly measuring something.
  if (health != null && health.avgActiveEnergyKcal >= 150) {
    return FormulaTdee(
      bmr: bmr,
      tdee: bmr * 1.2 + health.avgActiveEnergyKcal,
      source: TdeeSource.healthData,
      detail: '${health.avgActiveEnergyKcal.round()} kcal/day active energy',
    );
  }

  final answers = profile.preciseCalorieTrackingEnabled ? profile.preciseActivityInput : null;
  if (answers != null) {
    return FormulaTdee(
      bmr: bmr,
      tdee: answers.tdee(bmr: bmr, weightKg: weightKg),
      source: TdeeSource.activityAnswers,
      detail: answers.summary,
    );
  }

  final weekAgo = today.subtract(const Duration(days: 7));
  final sessionsLast7Days = sessions.where((s) => s.date.isAfter(weekAgo)).length;
  final selfReport = profile.initialActivityLevel;
  final isNewAccount = today.difference(profile.createdAt) < _newAccountWindow;
  if (selfReport != null && isNewAccount && sessionsLast7Days <= 1) {
    return FormulaTdee(
      bmr: bmr,
      tdee: bmr * selfReport.activityLevel.multiplier,
      source: TdeeSource.onboardingAnswer,
      detail: selfReport.label,
    );
  }

  final fourWeeksAgo = today.subtract(const Duration(days: 28));
  final recent = sessions.where((s) => s.date.isAfter(fourWeeksAgo)).toList();
  final minutes = typicalLoggedSessionMinutes(recent);
  final perSession = exerciseSessionKcal(
    weightKg: weightKg,
    minutes: minutes,
    intensity: ExerciseIntensity.moderate,
  );
  final perWeek = recent.length / 4;
  return FormulaTdee(
    bmr: bmr,
    tdee: bmr * JobActivityLevel.desk.neatFactor + perSession * recent.length / 28,
    source: TdeeSource.workoutLog,
    detail: '${perWeek.toStringAsFixed(perWeek == perWeek.roundToDouble() ? 0 : 1)} workouts/week × ~$minutes min',
  );
}

// ---------------------------------------------------------------------------
// Measured side
// ---------------------------------------------------------------------------

/// Maintenance calories measured from the user's own data: average logged
/// intake, corrected by how fast their weight actually moved over the same
/// window. If you ate 1850 kcal/day and lost 1 kg/week, you must be burning
/// about 1850 + 1100 = 2950. This is what "adaptive" trackers do, and it
/// catches everything a formula can't — metabolism, NEAT, consistent
/// under-logging.
class MeasuredTdee {
  final double tdee;
  final double avgIntakeKcal;
  final double weightChangeKgPerWeek;
  final int loggedDays;
  final int windowDays;
  final int weighIns;

  const MeasuredTdee({
    required this.tdee,
    required this.avgIntakeKcal,
    required this.weightChangeKgPerWeek,
    required this.loggedDays,
    required this.windowDays,
    required this.weighIns,
  });
}

/// Why [measureTdeeFromLogs] couldn't produce a number yet, phrased for the
/// user.
class MeasuredTdeeStatus {
  final MeasuredTdee? result;
  final String? missing;

  const MeasuredTdeeStatus._(this.result, this.missing);
}

const _measureWindowDays = 42;
const _minLoggedDays = 14;
const _minWeighIns = 3;
const _minWeighInSpanDays = 14;

/// Weigh-ins more than this far from the window's median are treated as
/// typos (e.g. 109 lb typed instead of 209) and ignored here.
const _weightOutlierFraction = 0.07;

/// See [MeasuredTdee]. Looks at the last 6 weeks, never including today
/// (still being logged). Days with no food logged — or so little that it
/// was obviously a partial log — are skipped rather than counted as zero.
MeasuredTdeeStatus measureTdeeFromLogs({
  required List<FoodEntry> foodEntries,
  required List<WeightEntry> weightEntries,
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final windowStart = today.subtract(const Duration(days: _measureWindowDays));

  final intakeByDay = <DateTime, double>{};
  for (final entry in foodEntries) {
    final day = _dateOnly(entry.date);
    if (day.isBefore(windowStart) || !day.isBefore(today)) continue;
    intakeByDay[day] = (intakeByDay[day] ?? 0) + entry.calories;
  }
  final dailyValues = intakeByDay.values.where((v) => v > 0).toList()..sort();
  if (dailyValues.length < _minLoggedDays) {
    return MeasuredTdeeStatus._(
      null,
      'Log food for at least $_minLoggedDays days (${dailyValues.length} so far in the last 6 weeks)',
    );
  }
  final medianIntake = dailyValues[dailyValues.length ~/ 2];
  final fullDays = dailyValues.where((v) => v >= medianIntake * 0.5).toList();

  final firstLoggedDay = intakeByDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  final spanDays = today.difference(firstLoggedDay).inDays;
  if (fullDays.length < spanDays * 0.7) {
    return MeasuredTdeeStatus._(
      null,
      'Log food on most days — ${fullDays.length} of the last $spanDays days are logged',
    );
  }
  final avgIntake = fullDays.reduce((a, b) => a + b) / fullDays.length;

  // Drop typos entry by entry (so one bad reading doesn't take a day's
  // real ones down with it), then average same-day weigh-ins.
  final windowEntries = weightEntries
      .where((e) => !_dateOnly(e.date).isBefore(windowStart) && !_dateOnly(e.date).isAfter(today))
      .toList();
  if (windowEntries.isEmpty) {
    return const MeasuredTdeeStatus._(null, 'Log your weight at least once a week');
  }
  final sortedKg = windowEntries.map((e) => e.weightKg).toList()..sort();
  final medianKg = sortedKg[sortedKg.length ~/ 2];
  final weightsByDay = <DateTime, List<double>>{};
  for (final entry in windowEntries) {
    if ((entry.weightKg - medianKg).abs() > medianKg * _weightOutlierFraction) continue;
    weightsByDay.putIfAbsent(_dateOnly(entry.date), () => []).add(entry.weightKg);
  }
  final points = [
    for (final e in weightsByDay.entries) (day: e.key, kg: e.value.reduce((a, b) => a + b) / e.value.length),
  ]..sort((a, b) => a.day.compareTo(b.day));
  final weighInSpan = points.isEmpty ? 0 : points.last.day.difference(points.first.day).inDays;
  if (points.length < _minWeighIns || weighInSpan < _minWeighInSpanDays) {
    return MeasuredTdeeStatus._(
      null,
      'Log your weight at least $_minWeighIns times over 2+ weeks (${points.length} in the last 6 weeks)',
    );
  }

  // Least-squares slope, kg per day.
  final xs = [for (final p in points) p.day.difference(windowStart).inDays.toDouble()];
  final ys = [for (final p in points) p.kg];
  final meanX = xs.reduce((a, b) => a + b) / xs.length;
  final meanY = ys.reduce((a, b) => a + b) / ys.length;
  var num = 0.0, den = 0.0;
  for (var i = 0; i < xs.length; i++) {
    num += (xs[i] - meanX) * (ys[i] - meanY);
    den += (xs[i] - meanX) * (xs[i] - meanX);
  }
  final slopeKgPerDay = den == 0 ? 0.0 : num / den;
  final tdee = avgIntake - slopeKgPerDay * kcalPerKgBodyWeight;

  if (tdee < 1000 || tdee > 6000) {
    return const MeasuredTdeeStatus._(
      null,
      "Your intake and weight trend don't add up yet — keep logging consistently",
    );
  }

  return MeasuredTdeeStatus._(
    MeasuredTdee(
      tdee: tdee,
      avgIntakeKcal: avgIntake,
      weightChangeKgPerWeek: slopeKgPerDay * 7,
      loggedDays: fullDays.length,
      windowDays: math.min(spanDays, _measureWindowDays),
      weighIns: points.length,
    ),
    null,
  );
}

// ---------------------------------------------------------------------------
// Putting it together
// ---------------------------------------------------------------------------

/// Everything behind today's calorie target, so any screen can show the
/// number *and* explain it without recomputing anything differently.
class DailyTarget {
  /// What to eat today, kcal.
  final double kcal;

  /// Estimated maintenance (TDEE) actually used.
  final double maintenanceKcal;
  final FormulaTdee formula;
  final MeasuredTdeeStatus measuredStatus;

  /// How much [measuredStatus]'s result is trusted vs. [formula] (0-1). 0
  /// when no measured result or the user turned learning off.
  final double measuredWeight;
  final GoalMode mode;

  /// Signed kcal adjustment the goal applies (negative for a deficit).
  final double goalAdjustmentKcal;
  final int? cycleAdjustmentKcal;

  /// True when the goal would have gone below the safe minimum and was
  /// raised to it.
  final bool raisedToMinimum;
  final double weightKg;

  const DailyTarget({
    required this.kcal,
    required this.maintenanceKcal,
    required this.formula,
    required this.measuredStatus,
    required this.measuredWeight,
    required this.mode,
    required this.goalAdjustmentKcal,
    required this.cycleAdjustmentKcal,
    required this.raisedToMinimum,
    required this.weightKg,
  });

  MeasuredTdee? get measured => measuredStatus.result;
  bool get usesMeasured => measuredWeight > 0;
}

/// Commonly cited floor below which a daily target shouldn't go without
/// medical supervision.
double minimumSafeCalories(Sex sex) => sex == Sex.male ? 1500 : 1200;

/// Today's calorie target — the single calculation every screen, the home
/// widget, and the charts share, so they can never disagree.
///
/// Maintenance is the formula estimate, blended with the measured-from-logs
/// estimate once there's enough data (trusted more the more days there
/// are: 50% at 2 weeks up to 90% at 6 weeks). Then the goal's deficit/
/// surplus and the optional luteal-phase adjustment are applied.
DailyTarget? computeDailyTarget({
  required UserProfile? profile,
  required NutritionGoal? goal,
  required List<WeightEntry> weightEntries,
  required List<WorkoutSession> sessions,
  required List<FoodEntry> foodEntries,
  HealthActivitySummary? health,
  int? cycleAdjustmentKcal,
  double? weightKgOverride,
  DateTime? now,
}) {
  if (profile == null || profile.sex == null) return null;

  final weightKg = weightKgOverride ?? currentWeightKg(profile, weightEntries);
  final formula = estimateFormulaTdee(
    profile: profile,
    weightKg: weightKg,
    sessions: sessions,
    health: health,
    now: now,
  );
  final measuredStatus = measureTdeeFromLogs(
    foodEntries: foodEntries,
    weightEntries: weightEntries,
    now: now,
  );
  final measured = measuredStatus.result;

  // Measured TDEE describes the user at their *current* weight — when
  // projecting to another weight (target weight), only the formula can
  // scale, so shift the measured value by the formula's own difference.
  var measuredWeight = 0.0;
  var maintenance = formula.tdee;
  if (profile.useMeasuredTdee && measured != null) {
    final dataDays = measured.loggedDays.clamp(_minLoggedDays, _measureWindowDays);
    measuredWeight = 0.5 + 0.4 * (dataDays - _minLoggedDays) / (_measureWindowDays - _minLoggedDays);
    var measuredAtWeight = measured.tdee;
    if (weightKgOverride != null) {
      final atCurrent = estimateFormulaTdee(
        profile: profile,
        weightKg: currentWeightKg(profile, weightEntries),
        sessions: sessions,
        health: health,
        now: now,
      );
      measuredAtWeight += formula.tdee - atCurrent.tdee;
    }
    maintenance = measuredWeight * measuredAtWeight + (1 - measuredWeight) * formula.tdee;
  }

  final mode = goal?.mode ?? GoalMode.maintain;
  final delta = goal?.effectiveCalorieDelta ?? GoalIntensity.moderate.calorieDelta.toDouble();
  final adjustment = switch (mode) {
    GoalMode.deficit => -delta,
    GoalMode.surplus => delta,
    GoalMode.maintain => 0.0,
  };

  var kcal = maintenance + adjustment + (cycleAdjustmentKcal ?? 0);
  final floor = minimumSafeCalories(profile.sex!);
  final raised = kcal < floor;
  if (raised) kcal = floor;

  return DailyTarget(
    kcal: kcal,
    maintenanceKcal: maintenance,
    formula: formula,
    measuredStatus: measuredStatus,
    measuredWeight: measuredWeight,
    mode: mode,
    goalAdjustmentKcal: adjustment,
    cycleAdjustmentKcal: cycleAdjustmentKcal,
    raisedToMinimum: raised,
    weightKg: weightKg,
  );
}

String formatKcal(double kcal) => '${kcal.round()} kcal';
