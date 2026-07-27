import '../core/nutrition/label_parser.dart';

/// A barcode lookup result cached locally so re-scanning (or picking from
/// "Previously scanned") doesn't need a fresh network round-trip. Keyed by
/// [barcode] — scanning the same barcode again upserts this row instead of
/// creating a duplicate, which is what keeps a double-scan from showing up
/// twice in the list.
class ScannedProduct {
  final String barcode;
  final String name;
  final double? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final double? servingGrams;
  final DateTime lastScannedAt;

  const ScannedProduct({
    required this.barcode,
    required this.name,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.servingGrams,
    required this.lastScannedAt,
  });

  /// Recovers the [ParsedNutrition] this was cached from, so the same
  /// review screen a fresh scan uses (`showScanReviewScreen`) can be reused
  /// verbatim for re-logging or saving to Personal Foods from the cache.
  ParsedNutrition toParsedNutrition() => ParsedNutrition(
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        fiberG: fiberG,
        sugarG: sugarG,
        sodiumMg: sodiumMg,
        servingGrams: servingGrams,
      );

  Map<String, Object?> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'fiber_g': fiberG,
      'sugar_g': sugarG,
      'sodium_mg': sodiumMg,
      'serving_grams': servingGrams,
      'last_scanned_at': lastScannedAt.toIso8601String(),
    };
  }

  factory ScannedProduct.fromMap(Map<String, Object?> map) {
    return ScannedProduct(
      barcode: map['barcode'] as String,
      name: map['name'] as String,
      calories: (map['calories'] as num?)?.toDouble(),
      proteinG: (map['protein_g'] as num?)?.toDouble(),
      carbsG: (map['carbs_g'] as num?)?.toDouble(),
      fatG: (map['fat_g'] as num?)?.toDouble(),
      fiberG: (map['fiber_g'] as num?)?.toDouble(),
      sugarG: (map['sugar_g'] as num?)?.toDouble(),
      sodiumMg: (map['sodium_mg'] as num?)?.toDouble(),
      servingGrams: (map['serving_grams'] as num?)?.toDouble(),
      lastScannedAt: DateTime.parse(map['last_scanned_at'] as String),
    );
  }
}
