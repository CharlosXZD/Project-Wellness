import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/food_library.dart';
import '../../models/personal_food.dart';
import '../../repositories/nutrition_repository.dart';

/// Create or edit a personal food. Per-100g macros just like the built-in
/// library (see [PersonalFood.toFoodDef]) rather than a one-off logged
/// amount, so it shows up in search from now on and scales by grams like
/// any other food.
///
/// [scannedDraft] prefills the form (name + macros already normalized to
/// 100g by the scan flow, see `scan_screen.dart`) without putting the
/// screen into edit mode — it's still a fresh food to create, just with a
/// head start instead of blank fields.
class PersonalFoodEditorScreen extends StatefulWidget {
  final PersonalFood? existing;
  final String? initialName;
  final PersonalFood? scannedDraft;

  const PersonalFoodEditorScreen({
    super.key,
    this.existing,
    this.initialName,
    this.scannedDraft,
  });

  @override
  State<PersonalFoodEditorScreen> createState() => _PersonalFoodEditorScreenState();
}

class _PersonalFoodEditorScreenState extends State<PersonalFoodEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _fiberController;
  late final TextEditingController _sugarController;
  late final TextEditingController _sodiumController;
  late String _category;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final prefill = existing ?? widget.scannedDraft;
    _nameController = TextEditingController(text: prefill?.name ?? widget.initialName ?? '');
    _caloriesController =
        TextEditingController(text: prefill?.caloriesPer100g.toStringAsFixed(0) ?? '');
    _proteinController =
        TextEditingController(text: prefill?.proteinPer100g.toStringAsFixed(0) ?? '');
    _carbsController =
        TextEditingController(text: prefill?.carbsPer100g.toStringAsFixed(0) ?? '');
    _fatController = TextEditingController(text: prefill?.fatPer100g.toStringAsFixed(0) ?? '');
    _fiberController =
        TextEditingController(text: prefill?.fiberPer100g?.toStringAsFixed(0) ?? '');
    _sugarController =
        TextEditingController(text: prefill?.sugarPer100g?.toStringAsFixed(0) ?? '');
    _sodiumController =
        TextEditingController(text: prefill?.sodiumMgPer100g?.toStringAsFixed(0) ?? '');
    _category = prefill?.category ?? foodCategories.first;
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

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      double.tryParse(_caloriesController.text.trim()) != null;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final existing = widget.existing;
    final food = PersonalFood(
      id: existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      category: _category,
      caloriesPer100g: double.parse(_caloriesController.text.trim()),
      proteinPer100g: double.tryParse(_proteinController.text.trim()) ?? 0,
      carbsPer100g: double.tryParse(_carbsController.text.trim()) ?? 0,
      fatPer100g: double.tryParse(_fatController.text.trim()) ?? 0,
      fiberPer100g: double.tryParse(_fiberController.text.trim()),
      sugarPer100g: double.tryParse(_sugarController.text.trim()),
      sodiumMgPer100g: double.tryParse(_sodiumController.text.trim()),
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    final repo = context.read<NutritionRepository>();
    if (existing != null) {
      await repo.updatePersonalFood(food);
    } else {
      await repo.createPersonalFood(food);
    }
    if (mounted) Navigator.of(context).pop(food);
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this food?'),
        content: Text('This removes "${existing.name}" from your personal foods. This can\'t be undone.'),
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

    await context.read<NutritionRepository>().deletePersonalFood(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit personal food' : 'New personal food'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: scheme.error),
              tooltip: 'Delete',
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          TextField(
            controller: _nameController,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Food name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text('Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: foodCategories
                .map(
                  (c) => ChoiceChip(
                    label: Text(c),
                    selected: c == _category,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Text('Per 100g', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _caloriesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Calories'),
            onChanged: (_) => setState(() {}),
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
          const SizedBox(height: 20),
          Text('Optional', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
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
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: FilledButton(
          onPressed: !_canSave || _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Text(_isEditing ? 'Save changes' : 'Save food'),
        ),
      ),
    );
  }
}
