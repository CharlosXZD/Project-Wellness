import 'dart:convert';

import 'food_entry.dart' show MealType;
import 'ingredient.dart';

/// A saved, reusable food item: either a simple manual entry (no
/// ingredients — just totals typed in directly, the old "saved snack"
/// shape) or a "recipe" built from multiple [Ingredient]s (a smoothie, a
/// full meal) whose totals are the sum of its ingredients.
///
/// [defaultMealType] is which meal this combo logs as by default (snack,
/// or breakfast/lunch/dinner for combos built from the meal builder) — the
/// user can still override it at log time.
class SavedFoodCombo {
  final String id;
  final String name;
  final MealType defaultMealType;
  final List<Ingredient> ingredients;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// Summed from ingredients when this is a recipe; null for the "manual
  /// totals, no ingredients" shape, since there's nothing to sum and no
  /// separate field for typing these in by hand.
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final DateTime createdAt;

  const SavedFoodCombo({
    required this.id,
    required this.name,
    required this.defaultMealType,
    required this.ingredients,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    required this.createdAt,
  });

  /// Builds a combo from its ingredient list, summing totals — used by the
  /// recipe builder so the caller never has to add macros up by hand.
  factory SavedFoodCombo.fromIngredients({
    required String id,
    required String name,
    required MealType defaultMealType,
    required List<Ingredient> ingredients,
    required DateTime createdAt,
  }) {
    return SavedFoodCombo(
      id: id,
      name: name,
      defaultMealType: defaultMealType,
      ingredients: ingredients,
      calories: ingredients.fold(0.0, (s, i) => s + i.calories),
      proteinG: ingredients.fold(0.0, (s, i) => s + i.proteinG),
      carbsG: ingredients.fold(0.0, (s, i) => s + i.carbsG),
      fatG: ingredients.fold(0.0, (s, i) => s + i.fatG),
      fiberG: _sumIfAnyKnown(ingredients.map((i) => i.fiberG)),
      sugarG: _sumIfAnyKnown(ingredients.map((i) => i.sugarG)),
      sodiumMg: _sumIfAnyKnown(ingredients.map((i) => i.sodiumMg)),
      createdAt: createdAt,
    );
  }

  /// Sums the non-null values, or returns null if none of the ingredients
  /// have this nutrient known at all — distinct from a true zero.
  static double? _sumIfAnyKnown(Iterable<double?> values) {
    if (values.every((v) => v == null)) return null;
    return values.fold<double>(0.0, (s, v) => s + (v ?? 0));
  }

  bool get isRecipe => ingredients.isNotEmpty;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'default_meal_type': defaultMealType.name,
      'ingredients_json':
          ingredients.isEmpty ? null : jsonEncode(ingredients.map((i) => i.toJson()).toList()),
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'fiber_g': fiberG,
      'sugar_g': sugarG,
      'sodium_mg': sodiumMg,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavedFoodCombo.fromMap(Map<String, Object?> map) {
    final ingredientsJson = map['ingredients_json'] as String?;
    final ingredients = ingredientsJson == null
        ? const <Ingredient>[]
        : (jsonDecode(ingredientsJson) as List)
            .map((i) => Ingredient.fromJson((i as Map).cast<String, Object?>()))
            .toList();

    return SavedFoodCombo(
      id: map['id'] as String,
      name: map['name'] as String,
      defaultMealType: MealType.values.firstWhere(
        (m) => m.name == map['default_meal_type'],
        orElse: () => MealType.snack,
      ),
      ingredients: ingredients,
      calories: (map['calories'] as num).toDouble(),
      proteinG: (map['protein_g'] as num).toDouble(),
      carbsG: (map['carbs_g'] as num).toDouble(),
      fatG: (map['fat_g'] as num).toDouble(),
      fiberG: (map['fiber_g'] as num?)?.toDouble(),
      sugarG: (map['sugar_g'] as num?)?.toDouble(),
      sodiumMg: (map['sodium_mg'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
