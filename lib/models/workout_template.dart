class TemplateExercise {
  final String id;
  final String templateId;
  final String exerciseName;
  final String category;
  final int orderIndex;
  final int targetSets;
  final int targetReps;
  final int? durationSeconds;

  /// Baseline weight set when the workout was created, so the very first
  /// real session already has something to compare against instead of
  /// starting from 0. Null for templates created before this existed.
  final double? targetWeightKg;

  /// Per-instance override — even a normally-bilateral exercise (e.g.
  /// "Dumbbell Curl") can be marked unilateral for one specific template.
  /// Combined with `ExerciseDef.unilateral` via OR wherever unilateral is
  /// checked, since a built-in unilateral exercise should never be
  /// overridable back to bilateral by a stale `false` default here.
  final bool unilateral;

  const TemplateExercise({
    required this.id,
    required this.templateId,
    required this.exerciseName,
    required this.category,
    required this.orderIndex,
    this.targetSets = 3,
    this.targetReps = 10,
    this.durationSeconds,
    this.targetWeightKg,
    this.unilateral = false,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'template_id': templateId,
      'exercise_name': exerciseName,
      'category': category,
      'order_index': orderIndex,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'duration_seconds': durationSeconds,
      'target_weight_kg': targetWeightKg,
      'unilateral': unilateral ? 1 : 0,
    };
  }

  factory TemplateExercise.fromMap(Map<String, Object?> map) {
    return TemplateExercise(
      id: map['id'] as String,
      templateId: map['template_id'] as String,
      exerciseName: map['exercise_name'] as String,
      category: map['category'] as String,
      orderIndex: map['order_index'] as int,
      targetSets: (map['target_sets'] as num?)?.toInt() ?? 3,
      targetReps: (map['target_reps'] as num?)?.toInt() ?? 10,
      durationSeconds: (map['duration_seconds'] as num?)?.toInt(),
      targetWeightKg: (map['target_weight_kg'] as num?)?.toDouble(),
      unilateral: (map['unilateral'] as num?) == 1,
    );
  }
}

class WorkoutTemplate {
  final String id;
  final String dayName;
  final String name;
  final DateTime createdAt;
  final List<TemplateExercise> exercises;

  const WorkoutTemplate({
    required this.id,
    required this.dayName,
    required this.name,
    required this.createdAt,
    this.exercises = const [],
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'day_name': dayName,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WorkoutTemplate.fromMap(
    Map<String, Object?> map, {
    List<TemplateExercise> exercises = const [],
  }) {
    return WorkoutTemplate(
      id: map['id'] as String,
      dayName: map['day_name'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      exercises: exercises,
    );
  }
}
