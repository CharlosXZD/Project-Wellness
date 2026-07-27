enum GoalMode { maintain, deficit, surplus }

enum GoalIntensity { mild, moderate, aggressive }

extension GoalModeLabel on GoalMode {
  String get label {
    switch (this) {
      case GoalMode.maintain:
        return 'Maintain';
      case GoalMode.deficit:
        return 'Deficit';
      case GoalMode.surplus:
        return 'Surplus';
    }
  }
}

extension GoalIntensityValue on GoalIntensity {
  String get label {
    switch (this) {
      case GoalIntensity.mild:
        return 'Mild';
      case GoalIntensity.moderate:
        return 'Moderate';
      case GoalIntensity.aggressive:
        return 'Aggressive';
    }
  }

  /// Daily calorie adjustment magnitude in kcal.
  int get calorieDelta {
    switch (this) {
      case GoalIntensity.mild:
        return 250;
      case GoalIntensity.moderate:
        return 500;
      case GoalIntensity.aggressive:
        return 750;
    }
  }
}

class NutritionGoal {
  final GoalMode mode;
  final GoalIntensity intensity;
  final double? targetWeightKg;

  /// When set, overrides [intensity]'s preset calorie delta with an exact
  /// user-chosen kcal/day amount (e.g. a custom 1000 kcal surplus).
  final double? customCalorieDelta;
  final DateTime updatedAt;

  const NutritionGoal({
    required this.mode,
    required this.intensity,
    this.targetWeightKg,
    this.customCalorieDelta,
    required this.updatedAt,
  });

  /// The calorie delta actually used for target-calorie math: the custom
  /// amount if the user set one, otherwise the intensity preset.
  double get effectiveCalorieDelta => customCalorieDelta ?? intensity.calorieDelta.toDouble();

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'mode': mode.name,
      'intensity': intensity.name,
      'target_weight_kg': targetWeightKg,
      'custom_calorie_delta': customCalorieDelta,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory NutritionGoal.fromMap(Map<String, Object?> map) {
    return NutritionGoal(
      mode: GoalMode.values.firstWhere((m) => m.name == map['mode']),
      intensity: GoalIntensity.values.firstWhere((i) => i.name == map['intensity']),
      targetWeightKg: (map['target_weight_kg'] as num?)?.toDouble(),
      customCalorieDelta: (map['custom_calorie_delta'] as num?)?.toDouble(),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// One entry in the append-only log of every goal the user has ever set —
/// unlike [NutritionGoal] itself (a single overwritten "current goal" row),
/// this is what lets the medals system detect "completed a cut/bulk": did a
/// [WeightEntry] reach [targetWeightKg], in the goal's direction, while it
/// was the active goal (between [startedAt] and [endedAt], or now if still
/// active)? See `lib/data/medal_catalog.dart`.
class GoalHistoryEntry {
  final String id;
  final GoalMode mode;
  final double? targetWeightKg;
  final DateTime startedAt;
  final DateTime? endedAt;

  const GoalHistoryEntry({
    required this.id,
    required this.mode,
    this.targetWeightKg,
    required this.startedAt,
    this.endedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'mode': mode.name,
      'target_weight_kg': targetWeightKg,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }

  factory GoalHistoryEntry.fromMap(Map<String, Object?> map) {
    return GoalHistoryEntry(
      id: map['id'] as String,
      mode: GoalMode.values.firstWhere((m) => m.name == map['mode']),
      targetWeightKg: (map['target_weight_kg'] as num?)?.toDouble(),
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] == null ? null : DateTime.parse(map['ended_at'] as String),
    );
  }
}
