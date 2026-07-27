import 'package:uuid/uuid.dart';

import '../../models/food_entry.dart';
import '../../models/ingredient.dart';
import '../../models/saved_food_combo.dart';
import 'share_codec.dart';

Map<String, dynamic> _ingredientToJson(Ingredient i) => {
      'name': i.name,
      'calories': i.calories,
      'proteinG': i.proteinG,
      'carbsG': i.carbsG,
      'fatG': i.fatG,
      'fiberG': i.fiberG,
      'sugarG': i.sugarG,
      'sodiumMg': i.sodiumMg,
      'grams': i.grams,
    };

Ingredient _ingredientFromJson(Map<String, dynamic> json) {
  return Ingredient(
    name: json['name'] as String,
    calories: (json['calories'] as num).toDouble(),
    proteinG: (json['proteinG'] as num).toDouble(),
    carbsG: (json['carbsG'] as num).toDouble(),
    fatG: (json['fatG'] as num).toDouble(),
    fiberG: (json['fiberG'] as num?)?.toDouble(),
    sugarG: (json['sugarG'] as num?)?.toDouble(),
    sodiumMg: (json['sodiumMg'] as num?)?.toDouble(),
    grams: (json['grams'] as num?)?.toDouble(),
  );
}

Map<String, dynamic> _comboToJson(SavedFoodCombo combo) => {
      'name': combo.name,
      'defaultMealType': combo.defaultMealType.name,
      'ingredients': combo.ingredients.map(_ingredientToJson).toList(),
      'calories': combo.calories,
      'proteinG': combo.proteinG,
      'carbsG': combo.carbsG,
      'fatG': combo.fatG,
      'fiberG': combo.fiberG,
      'sugarG': combo.sugarG,
      'sodiumMg': combo.sodiumMg,
    };

SavedFoodCombo _comboFromJson(Map<String, dynamic> json) {
  return SavedFoodCombo(
    id: const Uuid().v4(),
    name: json['name'] as String,
    defaultMealType: MealType.values.firstWhere(
      (m) => m.name == json['defaultMealType'],
      orElse: () => MealType.snack,
    ),
    ingredients: (json['ingredients'] as List)
        .map((i) => _ingredientFromJson((i as Map).cast<String, dynamic>()))
        .toList(),
    calories: (json['calories'] as num).toDouble(),
    proteinG: (json['proteinG'] as num).toDouble(),
    carbsG: (json['carbsG'] as num).toDouble(),
    fatG: (json['fatG'] as num).toDouble(),
    fiberG: (json['fiberG'] as num?)?.toDouble(),
    sugarG: (json['sugarG'] as num?)?.toDouble(),
    sodiumMg: (json['sodiumMg'] as num?)?.toDouble(),
    createdAt: DateTime.now(),
  );
}

/// Encodes a saved snack or meal (with its ingredients, if it's a recipe)
/// into a short shareable code.
String encodeCombo(SavedFoodCombo combo) {
  return encodePayload(_comboToJson(combo), SharePrefix.combo);
}

SavedFoodCombo decodeCombo(String code) {
  final decoded = decodePayload(code);
  if (decoded.prefix != SharePrefix.combo) {
    throw const ShareCodeException('That code is not a snack/meal share.');
  }
  return _comboFromJson(decoded.json);
}
