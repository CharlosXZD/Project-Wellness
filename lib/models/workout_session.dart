/// One side of a unilateral pair, e.g. "Single Arm Tricep Extension" logs a
/// left [SessionSet] and a right [SessionSet] for what's shown as one
/// numbered set in the UI. `null` means a normal bilateral set.
enum SetSide { left, right }

extension SetSideX on SetSide {
  String get label => this == SetSide.left ? 'L' : 'R';
}

class SessionSet {
  final String id;
  final String sessionExerciseId;
  final int setIndex;
  final double weightKg;
  final int reps;
  final SetSide? side;

  const SessionSet({
    required this.id,
    required this.sessionExerciseId,
    required this.setIndex,
    required this.weightKg,
    required this.reps,
    this.side,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'session_exercise_id': sessionExerciseId,
      'set_index': setIndex,
      'weight_kg': weightKg,
      'reps': reps,
      'side': side == SetSide.left
          ? 'L'
          : side == SetSide.right
              ? 'R'
              : null,
    };
  }

  factory SessionSet.fromMap(Map<String, Object?> map) {
    final sideCode = map['side'] as String?;
    return SessionSet(
      id: map['id'] as String,
      sessionExerciseId: map['session_exercise_id'] as String,
      setIndex: map['set_index'] as int,
      weightKg: (map['weight_kg'] as num).toDouble(),
      reps: (map['reps'] as num).toInt(),
      side: sideCode == 'L'
          ? SetSide.left
          : sideCode == 'R'
              ? SetSide.right
              : null,
    );
  }
}

class SessionExercise {
  final String id;
  final String sessionId;
  final String exerciseName;
  final int orderIndex;
  final int? durationSeconds;
  final int? caloriesBurned;
  final double? distanceKm;
  final List<SessionSet> sets;

  const SessionExercise({
    required this.id,
    required this.sessionId,
    required this.exerciseName,
    required this.orderIndex,
    this.durationSeconds,
    this.caloriesBurned,
    this.distanceKm,
    this.sets = const [],
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'exercise_name': exerciseName,
      'order_index': orderIndex,
      'duration_seconds': durationSeconds,
      'calories_burned': caloriesBurned,
      'distance_km': distanceKm,
    };
  }

  factory SessionExercise.fromMap(
    Map<String, Object?> map, {
    List<SessionSet> sets = const [],
  }) {
    return SessionExercise(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      exerciseName: map['exercise_name'] as String,
      orderIndex: map['order_index'] as int,
      durationSeconds: (map['duration_seconds'] as num?)?.toInt(),
      caloriesBurned: (map['calories_burned'] as num?)?.toInt(),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      sets: sets,
    );
  }
}

class WorkoutSession {
  final String id;
  final String? templateId;
  final String dayName;
  final String name;
  final DateTime date;
  final int? durationMinutes;
  final List<SessionExercise> exercises;

  const WorkoutSession({
    required this.id,
    this.templateId,
    required this.dayName,
    required this.name,
    required this.date,
    this.durationMinutes,
    this.exercises = const [],
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'template_id': templateId,
      'day_name': dayName,
      'name': name,
      'date': date.toIso8601String(),
      'duration_minutes': durationMinutes,
    };
  }

  factory WorkoutSession.fromMap(
    Map<String, Object?> map, {
    List<SessionExercise> exercises = const [],
  }) {
    return WorkoutSession(
      id: map['id'] as String,
      templateId: map['template_id'] as String?,
      dayName: map['day_name'] as String,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      durationMinutes: (map['duration_minutes'] as num?)?.toInt(),
      exercises: exercises,
    );
  }
}
