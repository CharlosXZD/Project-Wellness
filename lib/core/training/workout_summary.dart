import '../../models/workout_session.dart';
import '../../models/workout_template.dart';

/// How one exercise in a just-finished session compares to its history —
/// "did more reps than last time", "top set is heavier than 3 months ago".
class ExerciseProgress {
  final String exerciseName;
  final int repsThisSession;
  final int? repsLastTime;
  final double topWeightKgThisSession;
  final double? topWeightKgLastTime;
  final double? topWeightKg3MonthsAgo;
  final bool isNewPr;

  const ExerciseProgress({
    required this.exerciseName,
    required this.repsThisSession,
    this.repsLastTime,
    required this.topWeightKgThisSession,
    this.topWeightKgLastTime,
    this.topWeightKg3MonthsAgo,
    required this.isNewPr,
  });

  int? get repsDelta => repsLastTime == null ? null : repsThisSession - repsLastTime!;
  double? get weightDeltaVs3MonthsAgo =>
      topWeightKg3MonthsAgo == null ? null : topWeightKgThisSession - topWeightKg3MonthsAgo!;
}

/// Builds a per-exercise comparison for a just-finished session against
/// [priorSessions] (everything logged *before* this one — the caller must
/// snapshot this before persisting the new session). Pure function, fed
/// entirely from already-loaded `TrainingRepository` state — no queries.
/// [template], if given, supplies the workout's baseline sets/reps/weight
/// (set on `TemplateBaselineScreen`) as the "last time" comparison for an
/// exercise with no real session history yet, so the very first logged
/// session already shows a delta instead of a blank comparison.
List<ExerciseProgress> buildWorkoutSummary({
  required WorkoutSession finished,
  required List<WorkoutSession> priorSessions,
  WorkoutTemplate? template,
}) {
  final sortedPrior = [...priorSessions]..sort((a, b) => b.date.compareTo(a.date));
  final progress = <ExerciseProgress>[];

  for (final exercise in finished.exercises) {
    if (exercise.sets.isEmpty) continue;

    final repsThisSession = exercise.sets.fold<int>(0, (sum, s) => sum + s.reps);
    final topWeightThisSession =
        exercise.sets.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);

    // Every prior session (across all history) that logged this exercise,
    // most-recent first.
    final priorForExercise = sortedPrior
        .expand((s) => s.exercises.where((e) => e.exerciseName == exercise.exerciseName))
        .where((e) => e.sets.isNotEmpty)
        .toList();

    int? repsLastTime;
    double? topWeightLastTime;
    if (priorForExercise.isNotEmpty) {
      final last = priorForExercise.first;
      repsLastTime = last.sets.fold<int>(0, (sum, s) => sum + s.reps);
      topWeightLastTime = last.sets.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);
    } else {
      final baselineMatches = template?.exercises
              .where((e) => e.exerciseName == exercise.exerciseName)
              .toList() ??
          const [];
      if (baselineMatches.isNotEmpty && baselineMatches.first.targetWeightKg != null) {
        repsLastTime = baselineMatches.first.targetReps;
        topWeightLastTime = baselineMatches.first.targetWeightKg;
      }
    }

    // The entry closest to 90 days ago, among sessions logged before then —
    // an approximation of "3 months ago" that degrades gracefully with
    // sparse history rather than requiring an exact match.
    double? topWeight3MonthsAgo;
    final threshold = finished.date.subtract(const Duration(days: 90));
    final priorOldEnough =
        sortedPrior.where((s) => !s.date.isAfter(threshold)).toList();
    if (priorOldEnough.isNotEmpty) {
      final closest = priorOldEnough.first; // most-recent among those old enough
      final match = closest.exercises
          .where((e) => e.exerciseName == exercise.exerciseName && e.sets.isNotEmpty)
          .toList();
      if (match.isNotEmpty) {
        topWeight3MonthsAgo =
            match.first.sets.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);
      }
    }

    final everLoggedTopWeight = priorForExercise
        .expand((e) => e.sets)
        .map((s) => s.weightKg)
        .fold<double>(0, (max, w) => w > max ? w : max);

    progress.add(ExerciseProgress(
      exerciseName: exercise.exerciseName,
      repsThisSession: repsThisSession,
      repsLastTime: repsLastTime,
      topWeightKgThisSession: topWeightThisSession,
      topWeightKgLastTime: topWeightLastTime,
      topWeightKg3MonthsAgo: topWeight3MonthsAgo,
      isNewPr: priorForExercise.isNotEmpty && topWeightThisSession > everLoggedTopWeight,
    ));
  }

  return progress;
}
