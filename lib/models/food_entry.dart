enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeLabel on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }
}

class FoodEntry {
  final String id;
  final DateTime date;
  final MealType mealType;
  final String name;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final double? grams;

  const FoodEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.grams,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'meal_type': mealType.name,
      'name': name,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'fiber_g': fiberG,
      'sugar_g': sugarG,
      'sodium_mg': sodiumMg,
      'grams': grams,
    };
  }

  factory FoodEntry.fromMap(Map<String, Object?> map) {
    return FoodEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      mealType: MealType.values.firstWhere(
        (m) => m.name == map['meal_type'],
        orElse: () => MealType.snack,
      ),
      name: map['name'] as String,
      calories: (map['calories'] as num).toDouble(),
      proteinG: (map['protein_g'] as num).toDouble(),
      carbsG: (map['carbs_g'] as num).toDouble(),
      fatG: (map['fat_g'] as num).toDouble(),
      fiberG: (map['fiber_g'] as num?)?.toDouble(),
      sugarG: (map['sugar_g'] as num?)?.toDouble(),
      sodiumMg: (map['sodium_mg'] as num?)?.toDouble(),
      grams: (map['grams'] as num?)?.toDouble(),
    );
  }
}
