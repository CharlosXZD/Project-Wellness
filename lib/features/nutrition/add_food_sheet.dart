import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/training/medal_unlock.dart';
import '../../models/food_entry.dart';
import '../../models/ingredient.dart';
import '../../repositories/nutrition_repository.dart';

/// Manual food entry form. Normally adds a [FoodEntry] to today's log and
/// pops `true`. When [pickerMode] is set, it instead pops an [Ingredient]
/// (name + macros the user typed in, no meal type, nothing logged) for a
/// recipe builder or a "save this scan as a snack" flow to use.
Future<Object?> showAddFoodSheet(
  BuildContext context, {
  String? initialName,
  double? initialCalories,
  double? initialProtein,
  double? initialCarbs,
  double? initialFat,
  bool pickerMode = false,
}) {
  return showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AddFoodSheet(
      initialName: initialName,
      initialCalories: initialCalories,
      initialProtein: initialProtein,
      initialCarbs: initialCarbs,
      initialFat: initialFat,
      pickerMode: pickerMode,
    ),
  );
}

class _AddFoodSheet extends StatefulWidget {
  final String? initialName;
  final double? initialCalories;
  final double? initialProtein;
  final double? initialCarbs;
  final double? initialFat;
  final bool pickerMode;

  const _AddFoodSheet({
    this.initialName,
    this.initialCalories,
    this.initialProtein,
    this.initialCarbs,
    this.initialFat,
    required this.pickerMode,
  });

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _fiberController;
  late final TextEditingController _sugarController;
  late final TextEditingController _sodiumController;
  MealType _mealType = MealType.breakfast;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _caloriesController = TextEditingController(
      text: widget.initialCalories?.toStringAsFixed(0) ?? '',
    );
    _proteinController = TextEditingController(
      text: (widget.initialProtein ?? 0).toStringAsFixed(0),
    );
    _carbsController = TextEditingController(
      text: (widget.initialCarbs ?? 0).toStringAsFixed(0),
    );
    _fatController = TextEditingController(
      text: (widget.initialFat ?? 0).toStringAsFixed(0),
    );
    _fiberController = TextEditingController();
    _sugarController = TextEditingController();
    _sodiumController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final calories = double.parse(_caloriesController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim()) ?? 0;
    final carbs = double.tryParse(_carbsController.text.trim()) ?? 0;
    final fat = double.tryParse(_fatController.text.trim()) ?? 0;
    final fiber = double.tryParse(_fiberController.text.trim());
    final sugar = double.tryParse(_sugarController.text.trim());
    final sodium = double.tryParse(_sodiumController.text.trim());

    if (widget.pickerMode) {
      final ingredient = Ingredient(
        name: name,
        calories: calories,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
        fiberG: fiber,
        sugarG: sugar,
        sodiumMg: sodium,
      );
      if (mounted) Navigator.of(context).pop(ingredient);
      return;
    }

    final entry = FoodEntry(
      id: const Uuid().v4(),
      date: DateTime.now(),
      mealType: _mealType,
      name: name,
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      fiberG: fiber,
      sugarG: sugar,
      sodiumMg: sodium,
    );

    await context.read<NutritionRepository>().addEntry(entry);
    if (mounted) await evaluateMedalsAndNotify(context);

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.pickerMode ? 'Add ingredient' : 'Log food',
                style: Theme.of(context).textTheme.titleLarge,
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
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Food'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _caloriesController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Calories'),
                validator: (value) {
                  final cal = double.tryParse(value?.trim() ?? '');
                  if (cal == null || cal < 0) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Protein (g)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Carbs (g)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Fat (g)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fiberController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Fiber (g, optional)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _sugarController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Sugar (g, optional)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _sodiumController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Sodium (mg, optional)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(widget.pickerMode ? 'Add ingredient' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
