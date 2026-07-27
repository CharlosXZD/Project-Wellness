import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/nutrition/label_parser.dart';
import '../../core/training/medal_unlock.dart';
import '../../models/food_entry.dart';
import '../../models/ingredient.dart';
import '../../repositories/nutrition_repository.dart';
import '../../widgets/secondary_nutrients_row.dart';

/// Full-screen review step after a nutrition-label scan — pushed as its
/// own route rather than a bottom sheet, so the camera preview isn't
/// visible behind it. Normally adds a [FoodEntry] to today's log and pops
/// `true`. When [pickerMode] is set, it instead pops an [Ingredient] for a
/// recipe builder or a "save this scan as a snack" flow to use.
///
/// The label already states calories/protein/carbs/fat per serving, so the
/// only thing the user should ever have to type is how many grams they're
/// actually eating — everything else is extrapolated from that. The
/// per-serving numbers scanned off the label are shown as editable fields
/// so a misread OCR value can be corrected before it's scaled.
///
/// When [normalizeTo100g] is set (adding a personal food from a scan), the
/// "how much are you eating" question doesn't apply — a personal food is
/// defined per 100g, full stop — so that field is hidden and the scale
/// target is fixed at 100g instead of a user-entered amount.
Future<Object?> showScanReviewScreen(
  BuildContext context, {
  required ParsedNutrition parsed,
  bool pickerMode = false,
  bool normalizeTo100g = false,
  String? initialName,
}) {
  return Navigator.of(context).push<Object?>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ScanReviewScreen(
        parsed: parsed,
        pickerMode: pickerMode,
        normalizeTo100g: normalizeTo100g,
        initialName: initialName,
      ),
    ),
  );
}

class ScanReviewScreen extends StatefulWidget {
  final ParsedNutrition parsed;
  final bool pickerMode;
  final bool normalizeTo100g;
  final String? initialName;

  const ScanReviewScreen({
    super.key,
    required this.parsed,
    required this.pickerMode,
    this.normalizeTo100g = false,
    this.initialName,
  });

  @override
  State<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends State<ScanReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initialName ?? '');
  late final TextEditingController _servingGramsController;
  late final TextEditingController _gramsController;
  late final TextEditingController _caloriesPerServingController;
  late final TextEditingController _proteinPerServingController;
  late final TextEditingController _carbsPerServingController;
  late final TextEditingController _fatPerServingController;
  late final TextEditingController _fiberPerServingController;
  late final TextEditingController _sugarPerServingController;
  late final TextEditingController _sodiumPerServingController;
  MealType _mealType = MealType.breakfast;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final servingText = widget.parsed.servingGrams?.toStringAsFixed(0) ?? '';
    _servingGramsController = TextEditingController(text: servingText);
    // Defaults to the label's own serving size — the common case is eating
    // exactly one serving — but the user can change it to whatever they
    // actually had.
    _gramsController = TextEditingController(text: servingText);
    _caloriesPerServingController = TextEditingController(
      text: widget.parsed.calories?.toStringAsFixed(0) ?? '',
    );
    _proteinPerServingController = TextEditingController(
      text: widget.parsed.proteinG?.toStringAsFixed(0) ?? '',
    );
    _carbsPerServingController = TextEditingController(
      text: widget.parsed.carbsG?.toStringAsFixed(0) ?? '',
    );
    _fatPerServingController = TextEditingController(
      text: widget.parsed.fatG?.toStringAsFixed(0) ?? '',
    );
    _fiberPerServingController = TextEditingController(
      text: widget.parsed.fiberG?.toStringAsFixed(0) ?? '',
    );
    _sugarPerServingController = TextEditingController(
      text: widget.parsed.sugarG?.toStringAsFixed(0) ?? '',
    );
    _sodiumPerServingController = TextEditingController(
      text: widget.parsed.sodiumMg?.toStringAsFixed(0) ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final source = widget.initialName != null ? 'Product found' : 'Label scanned';
      final message = widget.parsed.isEmpty
          ? "Couldn't read the label — fill in what's printed on it, then enter how many grams you're eating."
          : widget.parsed.canScaleByGrams
              ? '$source — double-check the numbers, then enter how many grams you\'re eating.'
              : "$source, but couldn't find a serving size — double-check the numbers below and fill it in.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingGramsController.dispose();
    _gramsController.dispose();
    _caloriesPerServingController.dispose();
    _proteinPerServingController.dispose();
    _carbsPerServingController.dispose();
    _fatPerServingController.dispose();
    _fiberPerServingController.dispose();
    _sugarPerServingController.dispose();
    _sodiumPerServingController.dispose();
    super.dispose();
  }

  double get _servingGrams => double.tryParse(_servingGramsController.text.trim()) ?? 0;
  double get _grams =>
      widget.normalizeTo100g ? 100 : (double.tryParse(_gramsController.text.trim()) ?? 0);
  double get _caloriesPerServing =>
      double.tryParse(_caloriesPerServingController.text.trim()) ?? 0;
  double get _proteinPerServing =>
      double.tryParse(_proteinPerServingController.text.trim()) ?? 0;
  double get _carbsPerServing =>
      double.tryParse(_carbsPerServingController.text.trim()) ?? 0;
  double get _fatPerServing =>
      double.tryParse(_fatPerServingController.text.trim()) ?? 0;
  double? get _fiberPerServing => double.tryParse(_fiberPerServingController.text.trim());
  double? get _sugarPerServing => double.tryParse(_sugarPerServingController.text.trim());
  double? get _sodiumPerServing => double.tryParse(_sodiumPerServingController.text.trim());

  double _scale(double perServing) =>
      _servingGrams > 0 ? perServing / _servingGrams * _grams : 0;

  double? _scaleOrNull(double? perServing) =>
      perServing == null || _servingGrams <= 0 ? null : perServing / _servingGrams * _grams;

  bool get _canSave => _servingGrams > 0 && _grams > 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_canSave || _saving) return;

    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final calories = _scale(_caloriesPerServing);
    final protein = _scale(_proteinPerServing);
    final carbs = _scale(_carbsPerServing);
    final fat = _scale(_fatPerServing);
    final fiber = _scaleOrNull(_fiberPerServing);
    final sugar = _scaleOrNull(_sugarPerServing);
    final sodium = _scaleOrNull(_sodiumPerServing);

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
        grams: _grams,
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
      grams: _grams,
    );

    await context.read<NutritionRepository>().addEntry(entry);
    if (mounted) await evaluateMedalsAndNotify(context);

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.normalizeTo100g
              ? 'Add personal food'
              : widget.pickerMode
                  ? 'Add ingredient'
                  : 'Log food',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Food'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a name'
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  'From the label — double-check these',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _servingGramsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Serving size (g)'),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final grams = double.tryParse(value?.trim() ?? '');
                    if (grams == null || grams <= 0) return 'Enter the label\'s serving size';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _caloriesPerServingController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Calories per serving'),
                  onChanged: (_) => setState(() {}),
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
                        controller: _proteinPerServingController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Protein (g)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _carbsPerServingController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Carbs (g)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _fatPerServingController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Fat (g)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fiberPerServingController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Fiber (g)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _sugarPerServingController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Sugar (g)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _sodiumPerServingController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Sodium (mg)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                if (!widget.normalizeTo100g) ...[
                  const SizedBox(height: 24),
                  Text(
                    'How much are you eating?',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gramsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Grams eaten'),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final grams = double.tryParse(value?.trim() ?? '');
                      if (grams == null || grams <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                ],
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
                      _MacroPreview(
                        label: 'kcal',
                        value: _scale(_caloriesPerServing).toStringAsFixed(0),
                      ),
                      _MacroPreview(
                        label: 'P',
                        value: '${_scale(_proteinPerServing).toStringAsFixed(0)}g',
                      ),
                      _MacroPreview(
                        label: 'C',
                        value: '${_scale(_carbsPerServing).toStringAsFixed(0)}g',
                      ),
                      _MacroPreview(
                        label: 'F',
                        value: '${_scale(_fatPerServing).toStringAsFixed(0)}g',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SecondaryNutrientsRow(
                  fiberG: _scaleOrNull(_fiberPerServing),
                  sugarG: _scaleOrNull(_sugarPerServing),
                  sodiumMg: _scaleOrNull(_sodiumPerServing),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (!_canSave || _saving) ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(
                            widget.normalizeTo100g
                                ? 'Continue'
                                : widget.pickerMode
                                    ? 'Add ingredient'
                                    : 'Save',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
