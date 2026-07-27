import '../core/nutrition/bmr_calculator.dart';

enum Sex { male, female }

extension SexLabel on Sex {
  String get label {
    switch (this) {
      case Sex.male:
        return 'Male';
      case Sex.female:
        return 'Female';
    }
  }
}

class UserProfile {
  final String name;
  final DateTime dateOfBirth;
  final double heightCm;
  final double weightKg;
  final Sex? sex;
  final DateTime createdAt;

  /// Self-reported starting activity level, asked at onboarding since a
  /// brand-new account has no workout history yet for
  /// [BmrCalculator.activityFromWeeklySessions] to read. Only used as a
  /// fallback while that history stays sparse — see
  /// `lib/core/nutrition/target_calories.dart`.
  final SelfReportedActivityLevel? initialActivityLevel;

  /// Opt-in richer activity questionnaire (see [jobActivityLevel],
  /// [exerciseDaysPerWeek], [exerciseIntensity]) that narrows the target
  /// calorie range when enabled — set from Goals & BMR.
  final bool preciseCalorieTrackingEnabled;
  final JobActivityLevel? jobActivityLevel;
  final int? exerciseDaysPerWeek;
  final ExerciseIntensity? exerciseIntensity;

  /// Whether the "are we missing your workouts?" nudge has already been
  /// dismissed, so it doesn't keep reappearing.
  final bool workoutLoggingNudgeDismissed;

  const UserProfile({
    required this.name,
    required this.dateOfBirth,
    required this.heightCm,
    required this.weightKg,
    this.sex,
    required this.createdAt,
    this.initialActivityLevel,
    this.preciseCalorieTrackingEnabled = false,
    this.jobActivityLevel,
    this.exerciseDaysPerWeek,
    this.exerciseIntensity,
    this.workoutLoggingNudgeDismissed = false,
  });

  /// Age in whole years, computed from [dateOfBirth] so it stays accurate
  /// as time passes rather than going stale like a stored integer would.
  int get age {
    final now = DateTime.now();
    var years = now.year - dateOfBirth.year;
    final hadBirthdayThisYear = now.month > dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
    if (!hadBirthdayThisYear) years -= 1;
    return years;
  }

  /// The [PreciseActivityInput] this profile describes, or null if the
  /// user hasn't filled in job activity + exercise days/intensity yet
  /// (independent of whether [preciseCalorieTrackingEnabled] is on, so
  /// turning the toggle back on doesn't lose previously entered answers).
  PreciseActivityInput? get preciseActivityInput {
    final job = jobActivityLevel;
    final days = exerciseDaysPerWeek;
    final intensity = exerciseIntensity;
    if (job == null || days == null || intensity == null) return null;
    return PreciseActivityInput(job: job, exerciseDaysPerWeek: days, intensity: intensity);
  }

  UserProfile copyWith({
    String? name,
    DateTime? dateOfBirth,
    double? heightCm,
    double? weightKg,
    Sex? sex,
    SelfReportedActivityLevel? initialActivityLevel,
    bool? preciseCalorieTrackingEnabled,
    JobActivityLevel? jobActivityLevel,
    int? exerciseDaysPerWeek,
    ExerciseIntensity? exerciseIntensity,
    bool? workoutLoggingNudgeDismissed,
  }) {
    return UserProfile(
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      sex: sex ?? this.sex,
      createdAt: createdAt,
      initialActivityLevel: initialActivityLevel ?? this.initialActivityLevel,
      preciseCalorieTrackingEnabled:
          preciseCalorieTrackingEnabled ?? this.preciseCalorieTrackingEnabled,
      jobActivityLevel: jobActivityLevel ?? this.jobActivityLevel,
      exerciseDaysPerWeek: exerciseDaysPerWeek ?? this.exerciseDaysPerWeek,
      exerciseIntensity: exerciseIntensity ?? this.exerciseIntensity,
      workoutLoggingNudgeDismissed:
          workoutLoggingNudgeDismissed ?? this.workoutLoggingNudgeDismissed,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'name': name,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'sex': sex?.name,
      'created_at': createdAt.toIso8601String(),
      'date_of_birth': dateOfBirth.toIso8601String(),
      'initial_activity_level': initialActivityLevel?.name,
      'precise_calorie_tracking_enabled': preciseCalorieTrackingEnabled ? 1 : 0,
      'job_activity_level': jobActivityLevel?.name,
      'exercise_days_per_week': exerciseDaysPerWeek,
      'exercise_intensity': exerciseIntensity?.name,
      'workout_nudge_dismissed': workoutLoggingNudgeDismissed ? 1 : 0,
    };
  }

  factory UserProfile.fromMap(Map<String, Object?> map) {
    final dobRaw = map['date_of_birth'] as String?;
    final dateOfBirth = dobRaw != null
        ? DateTime.parse(dobRaw)
        : DateTime(DateTime.now().year - (map['age'] as int), 1, 1);

    return UserProfile(
      name: map['name'] as String,
      dateOfBirth: dateOfBirth,
      heightCm: (map['height_cm'] as num).toDouble(),
      weightKg: (map['weight_kg'] as num).toDouble(),
      sex: map['sex'] == null
          ? null
          : Sex.values.firstWhere((s) => s.name == map['sex']),
      createdAt: DateTime.parse(map['created_at'] as String),
      initialActivityLevel: map['initial_activity_level'] == null
          ? null
          : SelfReportedActivityLevel.values
              .firstWhere((l) => l.name == map['initial_activity_level']),
      preciseCalorieTrackingEnabled: (map['precise_calorie_tracking_enabled'] as num?) == 1,
      jobActivityLevel: map['job_activity_level'] == null
          ? null
          : JobActivityLevel.values.firstWhere((j) => j.name == map['job_activity_level']),
      exerciseDaysPerWeek: (map['exercise_days_per_week'] as num?)?.toInt(),
      exerciseIntensity: map['exercise_intensity'] == null
          ? null
          : ExerciseIntensity.values.firstWhere((e) => e.name == map['exercise_intensity']),
      workoutLoggingNudgeDismissed: (map['workout_nudge_dismissed'] as num?) == 1,
    );
  }
}
