enum SplitType { pushPullLegs, upperLower, fullBody, broSplit, pilates, custom }

extension SplitTypeDefaults on SplitType {
  String get label {
    switch (this) {
      case SplitType.pushPullLegs:
        return 'Push Pull Legs';
      case SplitType.upperLower:
        return 'Upper / Lower';
      case SplitType.fullBody:
        return 'Full Body';
      case SplitType.broSplit:
        return 'Bro Split';
      case SplitType.pilates:
        return 'Pilates';
      case SplitType.custom:
        return 'Custom';
    }
  }

  List<String> get defaultDayNames {
    switch (this) {
      case SplitType.pushPullLegs:
        return const ['Push', 'Pull', 'Legs'];
      case SplitType.upperLower:
        return const ['Upper', 'Lower'];
      case SplitType.fullBody:
        return const ['Full Body'];
      case SplitType.broSplit:
        return const ['Chest', 'Back', 'Shoulders', 'Arms', 'Legs'];
      // Note: 'Arms' is a day-name label here (matched case-insensitively
      // by suggestedCategoriesForDay in exercise_library.dart, which maps
      // it to the Biceps/Triceps/Forearms categories), not itself a
      // category in exerciseCategories.
      case SplitType.pilates:
        return const ['Pilates'];
      case SplitType.custom:
        return const [];
    }
  }
}

class WorkoutSplit {
  final SplitType type;
  final String name;
  final List<String> dayNames;
  final DateTime createdAt;

  const WorkoutSplit({
    required this.type,
    required this.name,
    required this.dayNames,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'type': type.name,
      'name': name,
      'day_names': dayNames.join('|'),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WorkoutSplit.fromMap(Map<String, Object?> map) {
    return WorkoutSplit(
      type: SplitType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => SplitType.custom,
      ),
      name: map['name'] as String,
      dayNames: (map['day_names'] as String)
          .split('|')
          .where((d) => d.isNotEmpty)
          .toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
