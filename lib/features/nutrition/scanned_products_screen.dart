import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/food_library.dart';
import '../../models/ingredient.dart';
import '../../models/personal_food.dart';
import '../../models/scanned_product.dart';
import '../../repositories/nutrition_repository.dart';
import 'personal_food_editor_screen.dart';
import 'scan_review_screen.dart';

/// Barcode lookups cached from past scans (see
/// `NutritionRepository.upsertScannedProduct`) — tap one to log it straight
/// to today without pointing the camera at it again, or save it to Personal
/// Foods. Reuses `showScanReviewScreen`, the same review step a fresh scan
/// goes through, so grams-eaten scaling and per-100g normalization don't
/// need a second implementation.
class ScannedProductsScreen extends StatelessWidget {
  const ScannedProductsScreen({super.key});

  Future<void> _logAgain(BuildContext context, ScannedProduct product) async {
    await showScanReviewScreen(
      context,
      parsed: product.toParsedNutrition(),
      initialName: product.name,
    );
  }

  Future<void> _saveToPersonalFoods(
      BuildContext context, ScannedProduct product) async {
    final result = await showScanReviewScreen(
      context,
      parsed: product.toParsedNutrition(),
      pickerMode: true,
      normalizeTo100g: true,
      initialName: product.name,
    );
    if (result is! Ingredient || !context.mounted) return;

    final draft = PersonalFood(
      id: const Uuid().v4(),
      name: result.name,
      category: foodCategories.first,
      caloriesPer100g: result.calories,
      proteinPer100g: result.proteinG,
      carbsPer100g: result.carbsG,
      fatPer100g: result.fatG,
      fiberPer100g: result.fiberG,
      sugarPer100g: result.sugarG,
      sodiumMgPer100g: result.sodiumMg,
      createdAt: DateTime.now(),
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => PersonalFoodEditorScreen(existing: draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<NutritionRepository>().scannedProducts;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Previously scanned')),
      body: SafeArea(
        child: products.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner,
                          size: 40, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        "Nothing scanned yet — barcodes you look up show up here.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  for (final product in products)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey(product.barcode),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(Icons.delete_outline,
                              color: scheme.onErrorContainer),
                        ),
                        onDismissed: (_) => context
                            .read<NutritionRepository>()
                            .deleteScannedProduct(product.barcode),
                        child: Material(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _logAgain(context, product),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${product.calories?.toStringAsFixed(0) ?? '?'} kcal'
                                          '${product.servingGrams != null ? ' / ${product.servingGrams!.toStringAsFixed(0)}g' : ''}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.bookmark_add_outlined,
                                        size: 20),
                                    tooltip: 'Save to Personal Foods',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        _saveToPersonalFoods(context, product),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
