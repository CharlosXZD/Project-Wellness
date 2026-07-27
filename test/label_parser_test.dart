import 'package:flutter_test/flutter_test.dart';
import 'package:project_wellness/core/nutrition/label_parser.dart';

void main() {
  group('LabelParser.parse', () {
    test('reads a standard US label and ignores saturated fat', () {
      const text = '''
        Nutrition Facts
        Serving Size 40g
        Calories 190
        Total Fat 9g
        Saturated Fat 3g
        Trans Fat 0g
        Total Carbohydrate 22g
        Protein 4g
      ''';

      final parsed = LabelParser.parse(text);

      expect(parsed.servingGrams, 40);
      expect(parsed.calories, 190);
      expect(parsed.fatG, 9);
      expect(parsed.carbsG, 22);
      expect(parsed.proteinG, 4);
      expect(parsed.canScaleByGrams, isTrue);
    });

    test('prefers the kcal figure over kJ on a combined energy line', () {
      const text = '''
        per 100g
        Energy 1046kJ / 250kcal
        Fat 12.5g
        of which saturates 5g
        Carbohydrate 30g
        Protein 8g
      ''';

      final parsed = LabelParser.parse(text);

      expect(parsed.calories, 250);
      expect(parsed.fatG, 12.5);
      expect(parsed.servingGrams, 100);
    });

    test('falls back to a bare "fat" match only when "total fat" is absent', () {
      const text = 'Fat 12g\nSaturated Fat 5g\nCarbs 20g';

      final parsed = LabelParser.parse(text);

      expect(parsed.fatG, 12);
    });

    test('leaves servingGrams null when no serving size is present', () {
      const text = 'Calories 100\nProtein 5g';

      final parsed = LabelParser.parse(text);

      expect(parsed.servingGrams, isNull);
      expect(parsed.canScaleByGrams, isFalse);
    });
  });

  group('LabelParser.merge', () {
    test('takes the most common value per field across frames', () {
      final results = [
        const ParsedNutrition(calories: 190, proteinG: 4, servingGrams: 40),
        const ParsedNutrition(calories: 190, proteinG: 40, servingGrams: 40),
        const ParsedNutrition(calories: 900, proteinG: 4, servingGrams: 4),
      ];

      final merged = LabelParser.merge(results);

      expect(merged.calories, 190);
      expect(merged.proteinG, 4);
      expect(merged.servingGrams, 40);
    });

    test('ignores nulls when picking the mode', () {
      final results = [
        const ParsedNutrition(fatG: null),
        const ParsedNutrition(fatG: 9),
        const ParsedNutrition(fatG: 9),
      ];

      final merged = LabelParser.merge(results);

      expect(merged.fatG, 9);
    });
  });
}
