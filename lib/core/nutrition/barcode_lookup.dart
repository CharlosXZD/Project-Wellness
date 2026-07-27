import 'dart:convert';

import 'package:http/http.dart' as http;

import 'label_parser.dart';

/// Outcome of a barcode lookup — distinguishes "no product with this code"
/// from a network/parsing failure so the UI can point at manual entry with
/// an accurate message either way.
enum BarcodeLookupStatus { found, notFound, error }

class BarcodeLookupResult {
  final BarcodeLookupStatus status;
  final String? productName;
  final ParsedNutrition? parsed;

  const BarcodeLookupResult._(this.status, this.productName, this.parsed);

  const BarcodeLookupResult.found({required String productName, required ParsedNutrition parsed})
      : this._(BarcodeLookupStatus.found, productName, parsed);

  const BarcodeLookupResult.notFound() : this._(BarcodeLookupStatus.notFound, null, null);

  const BarcodeLookupResult.error() : this._(BarcodeLookupStatus.error, null, null);
}

/// Looks up a scanned product barcode against Open Food Facts
/// (https://openfoodfacts.org) — a free, open, no-API-key nutrition
/// database — as an alternative to OCR-ing a label: matching a barcode to a
/// vetted database entry is inherently more reliable than parsing noisy
/// printed text.
class BarcodeLookup {
  static const _fields = 'product_name,nutriments,serving_quantity';

  static Future<BarcodeLookupResult> lookup(String code) async {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$code.json',
      {'fields': _fields},
    );

    final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (_) {
      return const BarcodeLookupResult.error();
    }

    if (response.statusCode != 200) return const BarcodeLookupResult.error();

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return const BarcodeLookupResult.error();
    }

    // Open Food Facts returns status: 0 (rather than a 404) when the
    // barcode isn't in its database.
    if (body['status'] != 1) return const BarcodeLookupResult.notFound();

    final product = body['product'] as Map<String, dynamic>?;
    if (product == null) return const BarcodeLookupResult.notFound();

    final name = (product['product_name'] as String?)?.trim();
    final nutriments = product['nutriments'] as Map<String, dynamic>?;
    if (name == null || name.isEmpty || nutriments == null) {
      return const BarcodeLookupResult.notFound();
    }

    final servingQuantity = _asDouble(product['serving_quantity']);

    // Prefer the "_serving" fields — Open Food Facts has already scaled
    // these to serving_quantity — over the "_100g" fields, since a real
    // serving size is more useful to the user than an arbitrary 100g basis.
    final useServing = servingQuantity != null && servingQuantity > 0;
    final suffix = useServing ? '_serving' : '_100g';

    final parsed = ParsedNutrition(
      calories: _asDouble(nutriments['energy-kcal$suffix']),
      proteinG: _asDouble(nutriments['proteins$suffix']),
      carbsG: _asDouble(nutriments['carbohydrates$suffix']),
      fatG: _asDouble(nutriments['fat$suffix']),
      fiberG: _asDouble(nutriments['fiber$suffix']),
      sugarG: _asDouble(nutriments['sugars$suffix']),
      // Open Food Facts states sodium in grams, not mg like a nutrition
      // label — convert so it matches ParsedNutrition's convention.
      sodiumMg: _asDouble(nutriments['sodium$suffix']) != null
          ? _asDouble(nutriments['sodium$suffix'])! * 1000
          : null,
      servingGrams: useServing ? servingQuantity : 100,
    );

    if (parsed.isEmpty) return const BarcodeLookupResult.notFound();

    return BarcodeLookupResult.found(productName: name, parsed: parsed);
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
