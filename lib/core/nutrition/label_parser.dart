class ParsedNutrition {
  final double? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;

  /// The serving size (in grams) the values above are stated per, e.g. the
  /// "40" in "Serving Size 40g" or the "100" in "per 100g". Null when the
  /// label's serving size couldn't be found in the OCR text, in which case
  /// the values above can't be scaled by grams eaten.
  final double? servingGrams;

  const ParsedNutrition({
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.servingGrams,
  });

  bool get isEmpty =>
      calories == null && proteinG == null && carbsG == null && fatG == null;

  /// Whether there's enough information to scale calories/protein/carbs/fat
  /// by an arbitrary grams-eaten amount.
  bool get canScaleByGrams => !isEmpty && servingGrams != null && servingGrams! > 0;
}

/// Best-effort extraction of calories/protein/carbs/fat from OCR text off
/// a nutrition facts label. Labels vary a lot in layout, so this is a
/// heuristic, not a guarantee — the caller should let the user review and
/// correct the result before saving.
class LabelParser {
  static ParsedNutrition parse(String text) {
    return ParsedNutrition(
      calories: _extractCalories(text),
      proteinG: _extract(text, const ['protein']),
      carbsG: _extract(text, const ['total carbohydrate', 'carbohydrate', 'carbs']),
      fatG: _extractFat(text),
      fiberG: _extract(text, const ['dietary fiber', 'fiber', 'fibre']),
      sugarG: _extract(text, const ['total sugars', 'sugars', 'sugar']),
      sodiumMg: _extractSodium(text),
      servingGrams: _extractServingGrams(text),
    );
  }

  static double? _extract(String text, List<String> keywords) {
    for (final keyword in keywords) {
      final pattern = RegExp(
        '${RegExp.escape(keyword)}\\s*[:\\-]?\\s*(\\d+(?:\\.\\d+)?)\\s*(?:g|kcal|cal)?',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(text);
      if (match != null) {
        final value = double.tryParse(match.group(1)!);
        if (value != null) return value;
      }
    }
    return null;
  }

  /// Many international labels show energy as "1046kJ/250kcal" — the
  /// generic keyword extraction would grab the first number after
  /// "Energy" (the kJ figure) rather than the kcal one. Matching on "kcal"
  /// directly sidesteps that; only labels with no kcal figure at all (rare)
  /// fall back to the plain "Calories"/"Energy" keyword scan.
  static double? _extractCalories(String text) {
    final kcalMatch =
        RegExp(r'(\d+(?:\.\d+)?)\s*kcal', caseSensitive: false).firstMatch(text);
    if (kcalMatch != null) {
      final value = double.tryParse(kcalMatch.group(1)!);
      if (value != null) return value;
    }
    return _extract(text, const ['calories', 'energy']);
  }

  /// A bare "fat" keyword match would just as happily latch onto
  /// "Saturated Fat 5g" or "Trans Fat 0g" as the real "Total Fat" line when
  /// OCR fails to read the word "Total" — excluding those prefixes keeps
  /// the fallback from reporting a sub-line's value as the label's total.
  static double? _extractFat(String text) {
    final totalFat = _extract(text, const ['total fat']);
    if (totalFat != null) return totalFat;

    final pattern = RegExp(
      r'(?<!saturated\s)(?<!trans\s)\bfat\s*[:\-]?\s*(\d+(?:\.\d+)?)\s*g?',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    if (match != null) {
      final value = double.tryParse(match.group(1)!);
      if (value != null) return value;
    }
    return null;
  }

  /// Sodium is stated in mg, not g like the other nutrients, so it needs its
  /// own unit match rather than [_extract]'s g/kcal/cal suffix.
  static double? _extractSodium(String text) {
    final pattern = RegExp(
      r'sodium\s*[:\-]?\s*(\d+(?:\.\d+)?)\s*mg\b',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    if (match != null) {
      final value = double.tryParse(match.group(1)!);
      if (value != null) return value;
    }
    return null;
  }

  /// Finds the serving size in grams, e.g. "40" in "Serving Size 40g" or
  /// "Serving size 1 bar (40g)", falling back to a "per 100g" style table
  /// header. Looks for the *last* gram figure near "serving size" since
  /// labels often list a household measure (cups, bars) before the gram
  /// equivalent in parentheses.
  static double? _extractServingGrams(String text) {
    final servingMatch =
        RegExp(r'serving\s*size([^\n]{0,40})', caseSensitive: false).firstMatch(text);
    if (servingMatch != null) {
      final window = servingMatch.group(1)!;
      final gramMatches =
          RegExp(r'(\d+(?:\.\d+)?)\s*g\b', caseSensitive: false).allMatches(window).toList();
      if (gramMatches.isNotEmpty) {
        final value = double.tryParse(gramMatches.last.group(1)!);
        if (value != null) return value;
      }
    }

    final perMatch =
        RegExp(r'per\s*(\d+(?:\.\d+)?)\s*g\b', caseSensitive: false).firstMatch(text);
    if (perMatch != null) {
      final value = double.tryParse(perMatch.group(1)!);
      if (value != null) return value;
    }

    return null;
  }

  /// Combines several OCR passes of the same label into one result, taking
  /// whichever value was read most often per field — one blurry/misread
  /// frame doesn't throw off the result the way a single-shot capture
  /// would.
  static ParsedNutrition merge(List<ParsedNutrition> results) {
    return ParsedNutrition(
      calories: _mode(results.map((r) => r.calories)),
      proteinG: _mode(results.map((r) => r.proteinG)),
      carbsG: _mode(results.map((r) => r.carbsG)),
      fatG: _mode(results.map((r) => r.fatG)),
      fiberG: _mode(results.map((r) => r.fiberG)),
      sugarG: _mode(results.map((r) => r.sugarG)),
      sodiumMg: _mode(results.map((r) => r.sodiumMg)),
      servingGrams: _mode(results.map((r) => r.servingGrams)),
    );
  }

  static double? _mode(Iterable<double?> values) {
    final nonNull = values.whereType<double>().toList();
    if (nonNull.isEmpty) return null;

    final counts = <double, int>{};
    for (final value in nonNull) {
      counts[value] = (counts[value] ?? 0) + 1;
    }

    var best = nonNull.first;
    var bestCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
      }
    }
    return best;
  }
}
