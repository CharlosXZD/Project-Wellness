import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/training/medal_unlock.dart';
import '../../models/food_def.dart';
import '../../models/food_entry.dart';
import '../../models/ingredient.dart';
import '../../repositories/nutrition_repository.dart';
import '../../widgets/secondary_nutrients_row.dart';

/// Shows the grams/meal-type sheet for [food]. Normally adds a [FoodEntry]
/// to today's log and pops `true`. When [pickerMode] is set, it instead
/// pops an [Ingredient] (no meal type, nothing written to the log) for a
/// recipe builder to add to its ingredient list.
Future<Object?> showLogFoodAmountSheet(
  BuildContext context,
  FoodDef food, {
  bool pickerMode = false,
}) {
  return showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _LogFoodAmountSheet(food: food, pickerMode: pickerMode),
  );
}

class _LogFoodAmountSheet extends StatefulWidget {
  final FoodDef food;
  final bool pickerMode;

  const _LogFoodAmountSheet({required this.food, required this.pickerMode});

  @override
  State<_LogFoodAmountSheet> createState() => _LogFoodAmountSheetState();
}

class _LogFoodAmountSheetState extends State<_LogFoodAmountSheet> {
  final _gramsController = TextEditingController(text: '100');
  MealType _mealType = MealType.breakfast;
  bool _saving = false;

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  double get _grams => double.tryParse(_gramsController.text.trim()) ?? 0;

  double get _calories => widget.food.caloriesPer100g * _grams / 100;
  double get _protein => widget.food.proteinPer100g * _grams / 100;
  double get _carbs => widget.food.carbsPer100g * _grams / 100;
  double get _fat => widget.food.fatPer100g * _grams / 100;
  double? get _fiber => _scaleOrNull(widget.food.fiberPer100g);
  double? get _sugar => _scaleOrNull(widget.food.sugarPer100g);
  double? get _sodium => _scaleOrNull(widget.food.sodiumMgPer100g);

  double? _scaleOrNull(double? per100g) => per100g == null ? null : per100g * _grams / 100;

  Future<void> _submit() async {
    if (_grams <= 0 || _saving) return;
    setState(() => _saving = true);

    if (widget.pickerMode) {
      final ingredient = Ingredient(
        name: widget.food.name,
        calories: _calories,
        proteinG: _protein,
        carbsG: _carbs,
        fatG: _fat,
        fiberG: _fiber,
        sugarG: _sugar,
        sodiumMg: _sodium,
        grams: _grams,
      );
      if (mounted) Navigator.of(context).pop(ingredient);
      return;
    }

    final entry = FoodEntry(
      id: const Uuid().v4(),
      date: DateTime.now(),
      mealType: _mealType,
      name: widget.food.name,
      calories: _calories,
      proteinG: _protein,
      carbsG: _carbs,
      fatG: _fat,
      fiberG: _fiber,
      sugarG: _sugar,
      sodiumMg: _sodium,
      grams: _grams,
    );

    await context.read<NutritionRepository>().addEntry(entry);
    if (mounted) await evaluateMedalsAndNotify(context);

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.food.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${widget.food.caloriesPer100g.toStringAsFixed(0)} kcal per 100g',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          if (!widget.pickerMode) ...[
            Wrap(
              spacing: 8,
              children: MealType.values.map((meal) {
                final selected = _mealType == meal;
                return ChoiceChip(
                  label: Text(meal.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _mealType = meal),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _gramsController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Grams'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MacroPreview(label: 'kcal', value: _calories.toStringAsFixed(0)),
                _MacroPreview(label: 'P', value: '${_protein.toStringAsFixed(0)}g'),
                _MacroPreview(label: 'C', value: '${_carbs.toStringAsFixed(0)}g'),
                _MacroPreview(label: 'F', value: '${_fat.toStringAsFixed(0)}g'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SecondaryNutrientsRow(fiberG: _fiber, sugarG: _sugar, sodiumMg: _sodium),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _grams <= 0 || _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(widget.pickerMode ? 'Add ingredient' : 'Add to log'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroPreview extends StatelessWidget {
  final String label;
  final String value;

  const _MacroPreview({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
