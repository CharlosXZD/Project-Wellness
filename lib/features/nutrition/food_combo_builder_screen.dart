import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/food_entry.dart';
import '../../models/ingredient.dart';
import '../../models/saved_food_combo.dart';
import '../../repositories/nutrition_repository.dart';
import '../../widgets/macro_bar.dart';
import '../../widgets/rect_button.dart';
import '../../widgets/secondary_nutrients_row.dart';
import 'add_food_sheet.dart';
import 'food_picker_screen.dart';
import 'scan_screen.dart';

/// Builds a saved combo ("recipe") from multiple ingredients — a smoothie
/// (protein scoop + fruit + yogurt + milk + ice) or a full meal — added via
/// the same food search and label scanner used elsewhere, rather than
/// typing one set of totals by hand.
class FoodComboBuilderScreen extends StatefulWidget {
  /// Meal types the user can tag this combo as. A single-value list (e.g.
  /// just [MealType.snack]) hides the chip picker since there's nothing to
  /// choose between.
  final List<MealType> mealTypeOptions;
  final MealType initialMealType;
  final SavedFoodCombo? existingCombo;

  const FoodComboBuilderScreen({
    super.key,
    required this.mealTypeOptions,
    required this.initialMealType,
    this.existingCombo,
  });

  @override
  State<FoodComboBuilderScreen> createState() => _FoodComboBuilderScreenState();
}

class _FoodComboBuilderScreenState extends State<FoodComboBuilderScreen> {
  late final _nameController = TextEditingController(text: widget.existingCombo?.name);
  late final List<Ingredient> _ingredients = List.of(widget.existingCombo?.ingredients ?? const []);
  late MealType _mealType;
  bool _saving = false;

  bool get _isEditing => widget.existingCombo != null;

  @override
  void initState() {
    super.initState();
    _mealType = widget.existingCombo?.defaultMealType ?? widget.initialMealType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  double get _calories => _ingredients.fold(0.0, (s, i) => s + i.calories);
  double get _protein => _ingredients.fold(0.0, (s, i) => s + i.proteinG);
  double get _carbs => _ingredients.fold(0.0, (s, i) => s + i.carbsG);
  double get _fat => _ingredients.fold(0.0, (s, i) => s + i.fatG);
  double? get _fiber => _sumIfAnyKnown(_ingredients.map((i) => i.fiberG));
  double? get _sugar => _sumIfAnyKnown(_ingredients.map((i) => i.sugarG));
  double? get _sodium => _sumIfAnyKnown(_ingredients.map((i) => i.sodiumMg));

  static double? _sumIfAnyKnown(Iterable<double?> values) {
    if (values.every((v) => v == null)) return null;
    return values.fold<double>(0.0, (s, v) => s + (v ?? 0));
  }

  Future<void> _addFromSearch() async {
    final result = await Navigator.of(context).push<Ingredient>(
      MaterialPageRoute(builder: (_) => const FoodPickerScreen(pickerMode: true)),
    );
    if (result != null && mounted) setState(() => _ingredients.add(result));
  }

  Future<void> _addFromScan() async {
    final result = await Navigator.of(context).push<Ingredient>(
      MaterialPageRoute(
        builder: (_) => const ScanScreen(mode: ScanResultMode.pickIngredient),
      ),
    );
    if (result != null && mounted) setState(() => _ingredients.add(result));
  }

  Future<void> _addManually() async {
    final result = await showAddFoodSheet(context, pickerMode: true);
    if (result is Ingredient && mounted) setState(() => _ingredients.add(result));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _ingredients.isEmpty || _saving) return;
    setState(() => _saving = true);

    final existing = widget.existingCombo;
    final combo = SavedFoodCombo.fromIngredients(
      id: existing?.id ?? const Uuid().v4(),
      name: name,
      defaultMealType: _mealType,
      ingredients: _ingredients,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    final repo = context.read<NutritionRepository>();
    if (existing != null) {
      await repo.updateCombo(combo);
    } else {
      await repo.addCombo(combo);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canSave = _nameController.text.trim().isNotEmpty && _ingredients.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit recipe' : 'Build a recipe')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Recipe name'),
            onChanged: (_) => setState(() {}),
          ),
          if (widget.mealTypeOptions.length > 1) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: widget.mealTypeOptions.map((meal) {
                return ChoiceChip(
                  label: Text(meal.label),
                  selected: _mealType == meal,
                  onSelected: (_) => setState(() => _mealType = meal),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          RectButton(
            icon: Icons.search,
            title: 'Search food',
            subtitle: 'Add fruit, dairy, and more from the food library',
            onTap: _addFromSearch,
          ),
          const SizedBox(height: 12),
          RectButton(
            icon: Icons.qr_code_scanner,
            title: 'Scan barcode or label',
            subtitle: 'Add a packaged item by its nutrition facts',
            onTap: _addFromScan,
          ),
          const SizedBox(height: 12),
          RectButton(
            icon: Icons.edit_outlined,
            title: 'Add manually',
            subtitle: "Type in the calories and macros for anything else",
            onTap: _addManually,
          ),
          const SizedBox(height: 20),
          if (_ingredients.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No ingredients yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            for (var i = 0; i < _ingredients.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey('${_ingredients[i].name}-$i'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                  ),
                  onDismissed: (_) => setState(() => _ingredients.removeAt(i)),
                  child: Material(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      title: Text(_ingredients[i].name),
                      subtitle: Text(
                        _ingredients[i].grams != null
                            ? '${_ingredients[i].grams!.toStringAsFixed(0)}g'
                            : 'P${_ingredients[i].proteinG.toStringAsFixed(0)} '
                                'C${_ingredients[i].carbsG.toStringAsFixed(0)} '
                                'F${_ingredients[i].fatG.toStringAsFixed(0)}',
                      ),
                      trailing: Text(
                        '${_ingredients[i].calories.toStringAsFixed(0)} kcal',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
          if (_ingredients.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_calories.toStringAsFixed(0)} kcal total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    MacroBar(proteinG: _protein, carbsG: _carbs, fatG: _fat),
                    const SizedBox(height: 16),
                    MacroLegendRow(proteinG: _protein, carbsG: _carbs, fatG: _fat),
                    const SizedBox(height: 12),
                    SecondaryNutrientsRow(fiberG: _fiber, sugarG: _sugar, sodiumMg: _sodium),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: FilledButton(
            onPressed: canSave && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(_isEditing ? 'Save changes' : 'Save recipe'),
          ),
        ),
      ),
    );
  }
}
