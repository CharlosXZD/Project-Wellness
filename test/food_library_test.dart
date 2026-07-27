import 'package:flutter_test/flutter_test.dart';
import 'package:project_wellness/data/food_library.dart';

void main() {
  group('foodLibrary', () {
    test('every food resolves an icon without throwing', () {
      for (final food in foodLibrary) {
        expect(() => iconForFood(food), returnsNormally, reason: food.name);
      }
    });

    test('every food has a known category', () {
      for (final food in foodLibrary) {
        expect(foodCategories, contains(food.category), reason: food.name);
      }
    });

    test('no duplicate names', () {
      final names = foodLibrary.map((f) => f.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('macro and secondary nutrient values are non-negative', () {
      for (final food in foodLibrary) {
        expect(food.caloriesPer100g, greaterThanOrEqualTo(0), reason: food.name);
        expect(food.proteinPer100g, greaterThanOrEqualTo(0), reason: food.name);
        expect(food.carbsPer100g, greaterThanOrEqualTo(0), reason: food.name);
        expect(food.fatPer100g, greaterThanOrEqualTo(0), reason: food.name);
        if (food.fiberPer100g != null) {
          expect(food.fiberPer100g, greaterThanOrEqualTo(0), reason: food.name);
        }
        if (food.sugarPer100g != null) {
          expect(food.sugarPer100g, greaterThanOrEqualTo(0), reason: food.name);
        }
        if (food.sodiumMgPer100g != null) {
          expect(food.sodiumMgPer100g, greaterThanOrEqualTo(0), reason: food.name);
        }
      }
    });
  });
}
