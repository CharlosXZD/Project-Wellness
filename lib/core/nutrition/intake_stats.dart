import '../../models/food_entry.dart';
import '../../models/user_profile.dart';
import '../../models/weight_entry.dart';
import '../../models/workout_session.dart';
import '../../repositories/nutrition_repository.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The first day this person has any data — the account's creation date,
/// or earlier if something older was logged/imported. Charts start here at
/// the earliest, so a "Year" view in someone's second month doesn't show
/// ten months of zeroes from before they installed the app.
DateTime firstUseDate({
  required UserProfile? profile,
  List<FoodEntry> foodEntries = const [],
  List<WeightEntry> weightEntries = const [],
  List<WorkoutSession> sessions = const [],
}) {
  var earliest = profile?.createdAt ?? DateTime.now();
  for (final date in [
    ...foodEntries.map((e) => e.date),
    ...weightEntries.map((e) => e.date),
    ...sessions.map((s) => s.date),
  ]) {
    if (date.isBefore(earliest)) earliest = date;
  }
  return _dateOnly(earliest);
}

/// Start of a trailing [days]-day window ending today, never earlier than
/// [firstUse].
DateTime chartRangeStart({required int days, required DateTime firstUse, DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final windowStart = today.subtract(Duration(days: days - 1));
  return windowStart.isBefore(firstUse) ? firstUse : windowStart;
}

/// Averages over *completed, logged* days only.
///
/// Two things used to drag these numbers around: days with nothing logged
/// counted as 0 kcal (a forgotten day looked like a fast), and today —
/// half-eaten — counted as a full day, so the average dropped every
/// morning and climbed back through the day.
class IntakeStats {
  final int loggedDays;

  /// Completed days in the range (today excluded) — the "of N" in
  /// "X of N days logged".
  final int completedDays;
  final double avgCalories;
  final double avgProteinG;
  final double avgCarbsG;
  final double avgFatG;

  const IntakeStats({
    required this.loggedDays,
    required this.completedDays,
    required this.avgCalories,
    required this.avgProteinG,
    required this.avgCarbsG,
    required this.avgFatG,
  });

  factory IntakeStats.from(List<DailyTotal> daily, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final completed = daily.where((d) => d.date.isBefore(today)).toList();
    final logged = completed.where((d) => d.totals.calories > 0).toList();
    double avg(double Function(DailyTotal d) f) =>
        logged.isEmpty ? 0 : logged.fold(0.0, (s, d) => s + f(d)) / logged.length;
    return IntakeStats(
      loggedDays: logged.length,
      completedDays: completed.length,
      avgCalories: avg((d) => d.totals.calories),
      avgProteinG: avg((d) => d.totals.proteinG),
      avgCarbsG: avg((d) => d.totals.carbsG),
      avgFatG: avg((d) => d.totals.fatG),
    );
  }
}
