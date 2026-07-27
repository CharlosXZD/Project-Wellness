import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/training/medal_unlock.dart';
import '../../models/food_entry.dart';
import '../../repositories/nutrition_repository.dart';

/// Shown when tapping a logged food entry on the nutrition screen — lets the
/// user fix a typo'd name or wrong macro, or delete the entry outright. The
/// entries themselves already supported deletion at the repository level
/// (`NutritionRepository.deleteEntry`); this sheet is what finally wires a UI
/// to it, plus a new `updateEntry` for corrections.
Future<void> showFoodEntryDetailSheet(BuildContext context, FoodEntry entry) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FoodEntryDetailSheet(entry: entry),
  );
}

class _FoodEntryDetailSheet extends StatefulWidget {
  final FoodEntry entry;

  const _FoodEntryDetailSheet({required this.entry});

  @override
  State<_FoodEntryDetailSheet> createState() => _FoodEntryDetailSheetState();
}

class _FoodEntryDetailSheetState extends State<_FoodEntryDetailSheet> {
  late final _nameController = TextEditingController(text: widget.entry.name);
  late final _caloriesController =
      TextEditingController(text: widget.entry.calories.toStringAsFixed(0));
  late final _proteinController =
      TextEditingController(text: widget.entry.proteinG.toStringAsFixed(0));
  late final _carbsController =
      TextEditingController(text: widget.entry.carbsG.toStringAsFixed(0));
  late final _fatController =
      TextEditingController(text: widget.entry.fatG.toStringAsFixed(0));
  late final _fiberController =
      TextEditingController(text: widget.entry.fiberG?.toStringAsFixed(0) ?? '');
  late final _sugarController =
      TextEditingController(text: widget.entry.sugarG?.toStringAsFixed(0) ?? '');
  late final _sodiumController =
      TextEditingController(text: widget.entry.sodiumMg?.toStringAsFixed(0) ?? '');
  late MealType _mealType = widget.entry.mealType;
  bool _saving = false;

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

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);

    final updated = FoodEntry(
      id: widget.entry.id,
      date: widget.entry.date,
      mealType: _mealType,
      name: _nameController.text.trim(),
      calories: double.tryParse(_caloriesController.text.trim()) ?? widget.entry.calories,
      proteinG: double.tryParse(_proteinController.text.trim()) ?? 0,
      carbsG: double.tryParse(_carbsController.text.trim()) ?? 0,
      fatG: double.tryParse(_fatController.text.trim()) ?? 0,
      fiberG: double.tryParse(_fiberController.text.trim()),
      sugarG: double.tryParse(_sugarController.text.trim()),
      sodiumMg: double.tryParse(_sodiumController.text.trim()),
      grams: widget.entry.grams,
    );

    await context.read<NutritionRepository>().updateEntry(updated);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text('This removes "${widget.entry.name}" from your log. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<NutritionRepository>().deleteEntry(widget.entry.id);
    if (!mounted) return;
    await reconcileMedalsAfterDeletion(context);
    if (mounted) Navigator.of(context).pop();
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Edit log entry', style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  tooltip: 'Delete',
                  onPressed: _delete,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: MealType.values.map((meal) {
                return ChoiceChip(
                  label: Text(meal.label),
                  selected: _mealType == meal,
                  onSelected: (_) => setState(() => _mealType = meal),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caloriesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Calories'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Protein (g)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Carbs (g)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Fat (g)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fiberController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Fiber (g)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _sugarController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Sugar (g)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _sodiumController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Sodium (mg)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
