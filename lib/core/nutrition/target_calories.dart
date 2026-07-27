import '../../models/nutrition_goal.dart';
import '../../models/user_profile.dart';
import '../../models/workout_session.dart';
import 'bmr_calculator.dart';

class TargetCalories {
  final double low;
  final double high;

  const TargetCalories({required this.low, required this.high});
}

/// Formats a low-high kcal/day pair for display — collapses to a single
/// number (e.g. "1839 kcal/day") when [low] and [high] are effectively
/// equal, which happens whenever "Precise calorie tracking" produced the
/// range (see `BmrCalculator.calculate`'s zero-width band): at that point
/// showing "1839–1839" would just be a redundant repeat of the same number,
/// not a range there's genuine uncertainty about.
String formatCalorieRange(double low, double high) {
  if ((high - low).abs() < 0.5) return '${((low + high) / 2).round()} kcal/day';
  return '${low.round()}–${high.round()} kcal/day';
}

/// A brand-new account has no in-app workout history yet, so the
/// [BmrCalculator.activityFromWeeklySessions] guess always starts at
/// Sedentary regardless of reality. While that's still true (first ~2
/// weeks, essentially no sessions logged), [UserProfile.initialActivityLevel]
/// — asked once at onboarding — stands in instead. Once real sessions
/// accumulate, the session-count heuristic naturally takes over on its own.
const _newAccountWindow = Duration(days: 14);

bool _hasSparseHistory(UserProfile profile, int sessionsLast7Days) {
  return sessionsLast7Days <= 1 && DateTime.now().difference(profile.createdAt) < _newAccountWindow;
}

/// Resolves which activity signal [BmrCalculator.calculate] should use,
/// in priority order: an explicit [overrideActivity] (real Health Connect/
/// Apple Health data, passed in by the caller) beats the opt-in "Precise
/// calorie tracking" questionnaire, which beats the onboarding self-report
/// fallback (only while [_hasSparseHistory]), which beats the plain
/// session-count heuristic (the default inside [BmrCalculator.calculate]
/// when both of the below are null).
({ActivityLevel? overrideActivity, PreciseActivityInput? preciseActivity}) resolveActivitySources({
  required UserProfile profile,
  required int sessionsLast7Days,
  ActivityLevel? overrideActivity,
}) {
  if (overrideActivity != null) {
    return (overrideActivity: overrideActivity, preciseActivity: null);
  }

  final preciseActivity =
      profile.preciseCalorieTrackingEnabled ? profile.preciseActivityInput : null;
  if (preciseActivity != null) {
    return (overrideActivity: null, preciseActivity: preciseActivity);
  }

  if (_hasSparseHistory(profile, sessionsLast7Days)) {
    return (overrideActivity: profile.initialActivityLevel?.activityLevel, preciseActivity: null);
  }

  return (overrideActivity: null, preciseActivity: null);
}

/// Computes the daily target calorie range from the user's profile, current
/// weight, recent training activity, and nutrition goal (deficit/surplus/
/// maintain). Mirrors the calculation shown on the Goals & BMR screen so the
/// two stay in sync.
TargetCalories? computeTargetCalories({
  required UserProfile? profile,
  required NutritionGoal? goal,
  required double? currentWeightKg,
  required List<WorkoutSession> sessions,
  ActivityLevel? overrideActivity,
  double? avgActiveEnergyKcal,
  int? cyclePhaseAdjustmentKcal,
}) {
  if (profile == null || profile.sex == null) return null;

  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  final sessionsLast7Days = sessions.where((s) => s.date.isAfter(weekAgo)).length;

  final resolved = resolveActivitySources(
    profile: profile,
    sessionsLast7Days: sessionsLast7Days,
    overrideActivity: overrideActivity,
  );

  final result = BmrCalculator.calculate(
    sex: profile.sex!,
    weightKg: currentWeightKg ?? profile.weightKg,
    heightCm: profile.heightCm,
    age: profile.age,
    sessionsLast7Days: sessionsLast7Days,
    overrideActivity: resolved.overrideActivity,
    avgActiveEnergyKcal: avgActiveEnergyKcal,
    preciseActivity: resolved.preciseActivity,
  );

  var low = result.tdeeLow;
  var high = result.tdeeHigh;
  final mode = goal?.mode ?? GoalMode.maintain;
  final delta = goal?.effectiveCalorieDelta ?? GoalIntensity.moderate.calorieDelta.toDouble();
  if (mode == GoalMode.deficit) {
    low -= delta;
    high -= delta;
  } else if (mode == GoalMode.surplus) {
    low += delta;
    high += delta;
  }

  if (cyclePhaseAdjustmentKcal != null) {
    low += cyclePhaseAdjustmentKcal;
    high += cyclePhaseAdjustmentKcal;
  }

  return TargetCalories(low: low, high: high);
}

/// Estimated maintenance calories *at the goal's target weight*, using the
/// same BMR/activity math as [computeTargetCalories] but with the target
/// weight substituted in. This is a directional recommendation — reaching
/// that weight and eating around this number is what would maintain it —
/// not a precise or binding target.
double? recommendedCaloriesAtTargetWeight({
  required UserProfile? profile,
  required NutritionGoal? goal,
  required List<WorkoutSession> sessions,
}) {
  final targetWeightKg = goal?.targetWeightKg;
  if (profile == null || profile.sex == null || targetWeightKg == null) return null;

  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  final sessionsLast7Days = sessions.where((s) => s.date.isAfter(weekAgo)).length;

  final resolved = resolveActivitySources(profile: profile, sessionsLast7Days: sessionsLast7Days);

  final result = BmrCalculator.calculate(
    sex: profile.sex!,
    weightKg: targetWeightKg,
    heightCm: profile.heightCm,
    age: profile.age,
    sessionsLast7Days: sessionsLast7Days,
    overrideActivity: resolved.overrideActivity,
    preciseActivity: resolved.preciseActivity,
  );

  return (result.tdeeLow + result.tdeeHigh) / 2;
}
