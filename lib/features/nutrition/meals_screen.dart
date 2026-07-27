import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/sharing/nutrition_share.dart';
import '../../core/training/medal_unlock.dart';
import '../../models/food_entry.dart';
import '../../models/saved_food_combo.dart';
import '../../repositories/nutrition_repository.dart';
import '../../widgets/action_card.dart';
import '../../widgets/import_code_dialog.dart';
import '../../widgets/rect_button.dart';
import '../../widgets/share_code_sheet.dart';
import 'create_snack_sheet.dart';
import 'food_combo_builder_screen.dart';

const _mealTypeOptions = [MealType.breakfast, MealType.lunch, MealType.dinner];

/// Saved meals — full breakfast/lunch/dinner combos, built the same way
/// as snacks (manual entry or a multi-ingredient recipe) but tagged as a
/// full meal type instead of a snack.
class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  void _shareMeal(BuildContext context, SavedFoodCombo meal) {
    showShareCodeSheet(
      context,
      title: 'Share ${meal.name}',
      code: encodeCombo(meal),
      shareSubject: 'My ${meal.name} meal',
    );
  }

  void _editMeal(BuildContext context, SavedFoodCombo meal) {
    if (meal.isRecipe) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FoodComboBuilderScreen(
            mealTypeOptions: _mealTypeOptions,
            initialMealType: meal.defaultMealType,
            existingCombo: meal,
          ),
        ),
      );
    } else {
      showCreateSnackSheet(
        context,
        defaultMealType: meal.defaultMealType,
        mealTypeOptions: _mealTypeOptions,
        existingCombo: meal,
      );
    }
  }

  Future<void> _logMeal(BuildContext context, SavedFoodCombo meal) async {
    final entry = FoodEntry(
      id: const Uuid().v4(),
      date: DateTime.now(),
      mealType: meal.defaultMealType,
      name: meal.name,
      calories: meal.calories,
      proteinG: meal.proteinG,
      carbsG: meal.carbsG,
      fatG: meal.fatG,
      fiberG: meal.fiberG,
      sugarG: meal.sugarG,
      sodiumMg: meal.sodiumMg,
    );
    await context.read<NutritionRepository>().addEntry(entry);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${meal.name} added as ${meal.defaultMealType.label.toLowerCase()}')),
      );
    }
    if (context.mounted) await evaluateMedalsAndNotify(context);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<NutritionRepository>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My meals')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            RectButton(
              icon: Icons.add_circle_outline,
              title: 'Create new meal',
              subtitle: 'Type in the numbers you already know',
              outlined: true,
              onTap: () => showCreateSnackSheet(
                context,
                defaultMealType: MealType.breakfast,
                mealTypeOptions: _mealTypeOptions,
              ),
            ),
            const SizedBox(height: 12),
            RectButton(
              icon: Icons.blender_outlined,
              title: 'Build a recipe',
              subtitle: 'Search foods or scan labels to build the whole plate',
              outlined: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FoodComboBuilderScreen(
                    mealTypeOptions: _mealTypeOptions,
                    initialMealType: MealType.breakfast,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tap to add to today',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            if (repo.meals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.restaurant_menu, size: 40, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      'No saved meals yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              )
            else
              for (final meal in repo.meals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: ValueKey(meal.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                    ),
                    onDismissed: (_) =>
                        context.read<NutritionRepository>().deleteCombo(meal.id),
                    child: ActionCard(
                      icon: Icons.restaurant_menu,
                      title: meal.name,
                      subtitle:
                          '${meal.defaultMealType.label} · ${meal.calories.toStringAsFixed(0)} kcal · '
                          'P${meal.proteinG.toStringAsFixed(0)} C${meal.carbsG.toStringAsFixed(0)} F${meal.fatG.toStringAsFixed(0)}'
                          '${meal.ingredients.length > 1 ? ' · ${meal.ingredients.length} ingredients' : ''}',
                      onTap: () => _logMeal(context, meal),
                      onEdit: () => _editMeal(context, meal),
                      onShare: () => _shareMeal(context, meal),
                    ),
                  ),
                ),
            Center(
              child: TextButton(
                onPressed: () => showImportCodeDialog(context),
                child: const Text('Import shared meal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
