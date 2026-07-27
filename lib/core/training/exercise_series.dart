import '../../models/workout_session.dart';

/// One session's top-set weight for a single exercise, on a specific date —
/// the unit `weight_history_screen.dart`'s chart already plots for overall
/// body weight; this is the same shape, per-exercise.
class ExerciseWeightPoint {
  final DateTime date;
  final double topWeightKg;

  const ExerciseWeightPoint({required this.date, required this.topWeightKg});
}

/// Every session that logged [exerciseName], oldest first, reduced to its
/// heaviest single set — mirrors `weight_series.dart`'s "pure function fed
/// from already-loaded repository state" shape, so charting an exercise's
/// progress needs no new queries.
List<ExerciseWeightPoint> buildExerciseWeightSeries(
  String exerciseName,
  List<WorkoutSession> sessions,
) {
  final points = <ExerciseWeightPoint>[];
  final sorted = [...sessions]..sort((a, b) => a.date.compareTo(b.date));

  for (final session in sorted) {
    for (final exercise in session.exercises) {
      if (exercise.exerciseName != exerciseName || exercise.sets.isEmpty) continue;
      final topWeight = exercise.sets.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);
      points.add(ExerciseWeightPoint(date: session.date, topWeightKg: topWeight));
    }
  }

  return points;
}
