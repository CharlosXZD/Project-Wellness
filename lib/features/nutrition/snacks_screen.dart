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
import 'scan_screen.dart';

class SnacksScreen extends StatelessWidget {
  const SnacksScreen({super.key});

  void _shareSnack(BuildContext context, SavedFoodCombo snack) {
    showShareCodeSheet(
      context,
      title: 'Share ${snack.name}',
      code: encodeCombo(snack),
      shareSubject: 'My ${snack.name} snack',
    );
  }

  void _editSnack(BuildContext context, SavedFoodCombo snack) {
    if (snack.isRecipe) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FoodComboBuilderScreen(
            mealTypeOptions: const [MealType.snack],
            initialMealType: MealType.snack,
            existingCombo: snack,
          ),
        ),
      );
    } else {
      showCreateSnackSheet(context, existingCombo: snack);
    }
  }

  Future<void> _logSnack(BuildContext context, SavedFoodCombo snack) async {
    final entry = FoodEntry(
      id: const Uuid().v4(),
      date: DateTime.now(),
      mealType: MealType.snack,
      name: snack.name,
      calories: snack.calories,
      proteinG: snack.proteinG,
      carbsG: snack.carbsG,
      fatG: snack.fatG,
      fiberG: snack.fiberG,
      sugarG: snack.sugarG,
      sodiumMg: snack.sodiumMg,
    );
    await context.read<NutritionRepository>().addEntry(entry);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${snack.name} added to today')),
      );
    }
    if (context.mounted) await evaluateMedalsAndNotify(context);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<NutritionRepository>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My snacks'),
        actions: [
          IconButton(
            tooltip: 'Scan a barcode or label to save as a snack',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ScanScreen(mode: ScanResultMode.saveAsSnack),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Tap to add to today',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            if (repo.snacks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.fastfood, size: 40, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      'No saved snacks yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              )
            else
              for (final snack in repo.snacks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: ValueKey(snack.id),
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
                        context.read<NutritionRepository>().deleteCombo(snack.id),
                    child: ActionCard(
                      icon: Icons.fastfood,
                      title: snack.name,
                      subtitle:
                          '${snack.calories.toStringAsFixed(0)} kcal · P${snack.proteinG.toStringAsFixed(0)} C${snack.carbsG.toStringAsFixed(0)} F${snack.fatG.toStringAsFixed(0)}'
                          '${snack.ingredients.length > 1 ? ' · ${snack.ingredients.length} ingredients' : ''}',
                      onTap: () => _logSnack(context, snack),
                      onEdit: () => _editSnack(context, snack),
                      onShare: () => _shareSnack(context, snack),
                    ),
                  ),
                ),
            RectButton(
              icon: Icons.add_circle_outline,
              title: 'Create new snack',
              subtitle: 'Type in the numbers you already know',
              outlined: true,
              onTap: () => showCreateSnackSheet(context),
            ),
            const SizedBox(height: 12),
            RectButton(
              icon: Icons.blender_outlined,
              title: 'Build a recipe',
              subtitle: 'Combine ingredients — a smoothie, a mix, etc.',
              outlined: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FoodComboBuilderScreen(
                    mealTypeOptions: [MealType.snack],
                    initialMealType: MealType.snack,
                  ),
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => showImportCodeDialog(context),
                child: const Text('Import shared snack'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
