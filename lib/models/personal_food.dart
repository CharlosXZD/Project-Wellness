import '../data/food_library.dart';
import 'food_def.dart';

/// A user-created food, persisted locally (see docs/SHARING_SYSTEM.md for
/// how these travel between devices via full backup). Per-100g macros just
/// like the built-in `foodLibrary`, so it renders and scales identically
/// everywhere a [FoodDef] is already handled (search, the grams sheet,
/// recipes) — see [toFoodDef].
class PersonalFood {
  final String id;
  final String name;
  final String category;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? sodiumMgPer100g;
  final DateTime createdAt;

  const PersonalFood({
    required this.id,
    required this.name,
    required this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.sodiumMgPer100g,
    required this.createdAt,
  });

  /// No per-food icon override — personal foods use the same category icon
  /// as any built-in item without one (see docs/NUTRITION_ICON_REGISTRY.md).
  FoodDef toFoodDef() => FoodDef(
        name: name,
        category: category,
        caloriesPer100g: caloriesPer100g,
        proteinPer100g: proteinPer100g,
        carbsPer100g: carbsPer100g,
        fatPer100g: fatPer100g,
        fiberPer100g: fiberPer100g,
        sugarPer100g: sugarPer100g,
        sodiumMgPer100g: sodiumMgPer100g,
      );

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'calories_per_100g': caloriesPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
      'fiber_per_100g': fiberPer100g,
      'sugar_per_100g': sugarPer100g,
      'sodium_mg_per_100g': sodiumMgPer100g,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PersonalFood.fromMap(Map<String, Object?> map) {
    return PersonalFood(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? foodCategories.first,
      caloriesPer100g: (map['calories_per_100g'] as num).toDouble(),
      proteinPer100g: (map['protein_per_100g'] as num).toDouble(),
      carbsPer100g: (map['carbs_per_100g'] as num).toDouble(),
      fatPer100g: (map['fat_per_100g'] as num).toDouble(),
      fiberPer100g: (map['fiber_per_100g'] as num?)?.toDouble(),
      sugarPer100g: (map['sugar_per_100g'] as num?)?.toDouble(),
      sodiumMgPer100g: (map['sodium_mg_per_100g'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
