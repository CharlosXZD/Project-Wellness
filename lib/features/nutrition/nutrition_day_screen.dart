import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/food_entry.dart';
import '../../repositories/nutrition_repository.dart';
import '../../widgets/macro_bar.dart';
import 'add_food_sheet.dart';
import 'food_entry_detail_sheet.dart';

/// One day's food log — reached from the week strip or the calendar. Step
/// between days with the arrows, tap an entry to fix/move/delete it, or add
/// something that was forgotten on the day.
class NutritionDayScreen extends StatefulWidget {
  final DateTime date;

  const NutritionDayScreen({super.key, required this.date});

  @override
  State<NutritionDayScreen> createState() => _NutritionDayScreenState();
}

class _NutritionDayScreenState extends State<NutritionDayScreen> {
  late DateTime _date = DateUtils.dateOnly(widget.date);

  bool get _isToday => DateUtils.isSameDay(_date, DateTime.now());

  void _shift(int days) => setState(() => _date = _date.add(Duration(days: days)));

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<NutritionRepository>();
    final entries = repo.entriesForDate(_date)..sort((a, b) => a.date.compareTo(b.date));
    final totals = repo.totalsForDate(_date);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isToday ? 'Today' : DateFormat.MMMEd().format(_date)),
        actions: [
          IconButton(
            tooltip: 'Previous day',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _shift(-1),
          ),
          IconButton(
            tooltip: 'Next day',
            icon: const Icon(Icons.chevron_right),
            onPressed: _isToday ? null : () => _shift(1),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddFoodSheet(context, date: _date),
        icon: const Icon(Icons.add),
        label: const Text('Add food'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${totals.calories.round()} kcal', style: textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    MacroBar(proteinG: totals.proteinG, carbsG: totals.carbsG, fatG: totals.fatG),
                    const SizedBox(height: 12),
                    MacroLegendRow(proteinG: totals.proteinG, carbsG: totals.carbsG, fatG: totals.fatG),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.restaurant, size: 40, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      'Nothing logged this day',
                      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              for (final meal in MealType.values)
                if (entries.any((e) => e.mealType == meal))
                  MealGroup(meal: meal, entries: entries.where((e) => e.mealType == meal).toList()),
          ],
        ),
      ),
    );
  }
}

/// One meal's entries under a header with the meal's calorie subtotal —
/// shared by this screen and the Nutrition screen's "Today" log.
class MealGroup extends StatelessWidget {
  final MealType meal;
  final List<FoodEntry> entries;

  const MealGroup({super.key, required this.meal, required this.entries});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final kcal = entries.fold(0.0, (sum, e) => sum + e.calories);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                Expanded(child: Text(meal.label, style: textTheme.titleSmall)),
                Text(
                  '${kcal.round()} kcal',
                  style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: scheme.outlineVariant.withValues(alpha: 0.5)),
                  _FoodRow(entry: entries[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  final FoodEntry entry;

  const _FoodRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final grams = entry.grams;
    return ListTile(
      onTap: () => showFoodEntryDetailSheet(context, entry),
      title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (grams != null) '${grams.toStringAsFixed(0)} g',
          'P ${entry.proteinG.toStringAsFixed(0)} · C ${entry.carbsG.toStringAsFixed(0)} · F ${entry.fatG.toStringAsFixed(0)}',
        ].join(' · '),
      ),
      trailing: Text(
        '${entry.calories.toStringAsFixed(0)} kcal',
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
