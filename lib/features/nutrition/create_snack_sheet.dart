import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/food_entry.dart';
import '../../models/saved_food_combo.dart';
import '../../repositories/nutrition_repository.dart';

/// Quick manual entry for a saved combo: just type the totals in directly
/// (no ingredient list) — the fast path for when you already know the
/// numbers. Used for both snacks and meals via [defaultMealType]. Pass
/// [mealTypeOptions] with more than one entry to let the user pick which one
/// before saving (hidden for snacks, where there's nothing to choose). Pass
/// [existingCombo] to edit it in place instead of creating a new one.
Future<void> showCreateSnackSheet(
  BuildContext context, {
  MealType defaultMealType = MealType.snack,
  List<MealType> mealTypeOptions = const [MealType.snack],
  SavedFoodCombo? existingCombo,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _CreateSnackSheet(
      defaultMealType: defaultMealType,
      mealTypeOptions: mealTypeOptions,
      existingCombo: existingCombo,
    ),
  );
}

class _CreateSnackSheet extends StatefulWidget {
  final MealType defaultMealType;
  final List<MealType> mealTypeOptions;
  final SavedFoodCombo? existingCombo;

  const _CreateSnackSheet({
    required this.defaultMealType,
    required this.mealTypeOptions,
    this.existingCombo,
  });

  @override
  State<_CreateSnackSheet> createState() => _CreateSnackSheetState();
}

class _CreateSnackSheetState extends State<_CreateSnackSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existingCombo?.name);
  late final _caloriesController = TextEditingController(
    text: widget.existingCombo?.calories.toStringAsFixed(0),
  );
  late final _proteinController = TextEditingController(
    text: widget.existingCombo?.proteinG.toStringAsFixed(0) ?? '0',
  );
  late final _carbsController = TextEditingController(
    text: widget.existingCombo?.carbsG.toStringAsFixed(0) ?? '0',
  );
  late final _fatController = TextEditingController(
    text: widget.existingCombo?.fatG.toStringAsFixed(0) ?? '0',
  );
  late final _fiberController = TextEditingController(
    text: widget.existingCombo?.fiberG?.toStringAsFixed(0) ?? '',
  );
  late final _sugarController = TextEditingController(
    text: widget.existingCombo?.sugarG?.toStringAsFixed(0) ?? '',
  );
  late final _sodiumController = TextEditingController(
    text: widget.existingCombo?.sodiumMg?.toStringAsFixed(0) ?? '',
  );
  bool _saving = false;
  late MealType _mealType = widget.existingCombo?.defaultMealType ?? widget.defaultMealType;

  bool get _isEditing => widget.existingCombo != null;
  bool get _isMeal => widget.defaultMealType != MealType.snack;

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

    final existing = widget.existingCombo;
    final combo = SavedFoodCombo(
      id: existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      defaultMealType: _mealType,
      ingredients: const [],
      calories: double.parse(_caloriesController.text.trim()),
      proteinG: double.tryParse(_proteinController.text.trim()) ?? 0,
      carbsG: double.tryParse(_carbsController.text.trim()) ?? 0,
      fatG: double.tryParse(_fatController.text.trim()) ?? 0,
      fiberG: double.tryParse(_fiberController.text.trim()),
      sugarG: double.tryParse(_sugarController.text.trim()),
      sodiumMg: double.tryParse(_sodiumController.text.trim()),
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
                _isEditing ? 'Edit ${_isMeal ? 'meal' : 'snack'}' : (_isMeal ? 'New meal' : 'New snack'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Save it once, add it to your day in one tap.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a name'
                    : null,
              ),
              if (_isMeal && widget.mealTypeOptions.length > 1) ...[
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
                      : Text(_isEditing ? 'Save changes' : (_isMeal ? 'Save meal' : 'Save snack')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
