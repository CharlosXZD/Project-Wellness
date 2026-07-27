import 'package:flutter/widgets.dart' show IconData;

class FoodDef {
  final String name;
  final String category;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  /// Secondary nutrients — optional because they aren't known for every
  /// food in the library (or a scanned/personal food), unlike the four
  /// core macros above which are always required.
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? sodiumMgPer100g;

  /// Direct icon override for this specific food (e.g. a literal apple
  /// glyph), used when one exists in Lucide/Material. Falls back to the
  /// category icon when null — see docs/NUTRITION_ICON_REGISTRY.md.
  final IconData? icon;

  const FoodDef({
    required this.name,
    required this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.sodiumMgPer100g,
    this.icon,
  });
}
