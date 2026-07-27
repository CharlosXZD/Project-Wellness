import 'package:uuid/uuid.dart';

import '../../models/custom_exercise.dart';
import '../../models/personal_food.dart';
import 'share_codec.dart';
import 'workout_share.dart';

/// Every custom exercise + personal food decoded from a `PWL1.` code, with
/// fresh IDs already assigned — same "fresh IDs on every import" rule as
/// every other share type (see docs/SHARING_SYSTEM.md §3). Merging this
/// against what the recipient already has (skipping anything already
/// present by name) is the caller's job — see
/// `TrainingRepository.mergeCustomExercises` / `NutritionRepository.mergePersonalFoods`.
class DecodedLibraryBundle {
  final List<CustomExercise> exercises;
  final List<PersonalFood> foods;

  const DecodedLibraryBundle({required this.exercises, required this.foods});
}

Map<String, dynamic> _personalFoodToJson(PersonalFood food) => {
      'name': food.name,
      'category': food.category,
      'caloriesPer100g': food.caloriesPer100g,
      'proteinPer100g': food.proteinPer100g,
      'carbsPer100g': food.carbsPer100g,
      'fatPer100g': food.fatPer100g,
      'fiberPer100g': food.fiberPer100g,
      'sugarPer100g': food.sugarPer100g,
      'sodiumMgPer100g': food.sodiumMgPer100g,
    };

PersonalFood _personalFoodFromJson(Map<String, dynamic> json) {
  return PersonalFood(
    id: const Uuid().v4(),
    name: json['name'] as String,
    category: json['category'] as String,
    caloriesPer100g: (json['caloriesPer100g'] as num).toDouble(),
    proteinPer100g: (json['proteinPer100g'] as num).toDouble(),
    carbsPer100g: (json['carbsPer100g'] as num).toDouble(),
    fatPer100g: (json['fatPer100g'] as num).toDouble(),
    fiberPer100g: (json['fiberPer100g'] as num?)?.toDouble(),
    sugarPer100g: (json['sugarPer100g'] as num?)?.toDouble(),
    sodiumMgPer100g: (json['sodiumMgPer100g'] as num?)?.toDouble(),
    createdAt: DateTime.now(),
  );
}

/// Encodes every custom exercise + personal food the user has into one
/// code — "Export my library" in `personal_exercises_screen.dart` and
/// `personal_foods_screen.dart`.
String encodeLibraryBundle({
  required List<CustomExercise> exercises,
  required List<PersonalFood> foods,
}) {
  final json = {
    'exercises': exercises.map(customExerciseToJson).toList(),
    'foods': foods.map(_personalFoodToJson).toList(),
  };
  return encodePayload(json, SharePrefix.library);
}

DecodedLibraryBundle decodeLibraryBundle(String code) {
  final decoded = decodePayload(code);
  if (decoded.prefix != SharePrefix.library) {
    throw const ShareCodeException('That code is not a library share.');
  }
  final json = decoded.json;
  final exercises = (json['exercises'] as List)
      .map((e) => customExerciseFromJson((e as Map).cast<String, dynamic>()))
      .toList();
  final foods = (json['foods'] as List)
      .map((f) => _personalFoodFromJson((f as Map).cast<String, dynamic>()))
      .toList();
  return DecodedLibraryBundle(exercises: exercises, foods: foods);
}

/// Which of [incoming] aren't already present in [existingNames] (matched
/// case-insensitive, trimmed) — the additive, never-overwrite matching rule
/// behind `TrainingRepository.mergeCustomExercises` and
/// `NutritionRepository.mergePersonalFoods`. Pulled out as a pure function
/// (no DB access) so the matching logic itself is unit-testable on its own.
List<T> newItemsByName<T>({
  required List<T> incoming,
  required Iterable<String> existingNames,
  required String Function(T) nameOf,
}) {
  final seen = existingNames.map((n) => n.trim().toLowerCase()).toSet();
  final result = <T>[];
  for (final item in incoming) {
    final key = nameOf(item).trim().toLowerCase();
    if (seen.add(key)) result.add(item);
  }
  return result;
}
