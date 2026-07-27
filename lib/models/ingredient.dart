/// One line item inside a [SavedFoodCombo] "recipe" — e.g. one scoop of
/// protein powder, a banana, a cup of milk. Plain macro numbers rather than
/// a [FoodDef] reference so a combo still displays correctly even if the
/// food library changes later, and so a scanned label (which has no
/// matching FoodDef at all) can be an ingredient too.
class Ingredient {
  final String name;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final double? grams;

  const Ingredient({
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

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
      'fiberG': fiberG,
      'sugarG': sugarG,
      'sodiumMg': sodiumMg,
      'grams': grams,
    };
  }

  factory Ingredient.fromJson(Map<String, Object?> json) {
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
}
