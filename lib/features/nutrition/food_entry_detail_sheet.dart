import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

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
    showDragHandle: true,
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
  late DateTime _date = widget.entry.date;
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
      date: _date,
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

  /// Moves the entry to another day (logged on the wrong one), keeping its
  /// time of day.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute));
  }

  /// Deletes straight away with an "Undo" snackbar, rather than a
  /// "this can't be undone" dialog — a mistaken delete is one tap to fix.
  Future<void> _delete() async {
    final repo = context.read<NutritionRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final entry = widget.entry;
    await repo.deleteEntry(entry.id);
    if (!mounted) return;
    await reconcileMedalsAfterDeletion(context);
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed "${entry.name}"'),
          action: SnackBarAction(label: 'Undo', onPressed: () => repo.addEntry(entry)),
        ),
      );
  }

  /// Logs a copy of this entry for right now — for the thing you eat every
  /// day, without searching for it again.
  Future<void> _logAgainToday() async {
    final entry = widget.entry;
    final messenger = ScaffoldMessenger.of(context);
    await context.read<NutritionRepository>().addEntry(
          FoodEntry(
            id: const Uuid().v4(),
            date: DateTime.now(),
            mealType: entry.mealType,
            name: entry.name,
            calories: entry.calories,
            proteinG: entry.proteinG,
            carbsG: entry.carbsG,
            fatG: entry.fatG,
            fiberG: entry.fiberG,
            sugarG: entry.sugarG,
            sodiumMg: entry.sodiumMg,
            grams: entry.grams,
          ),
        );
    if (!mounted) return;
    await evaluateMedalsAndNotify(context);
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text('Logged "${entry.name}" for today')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
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
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Day',
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  DateUtils.isSameDay(_date, DateTime.now()) ? 'Today' : DateFormat.yMMMEd().format(_date),
                ),
              ),
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
            if (!DateUtils.isSameDay(widget.entry.date, DateTime.now())) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _logAgainToday,
                  icon: const Icon(Icons.replay),
                  label: const Text('Log again today'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
