import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/food_entry.dart';
import '../../repositories/nutrition_repository.dart';
import 'food_entry_detail_sheet.dart';

/// Read-only view of a single past day's food log — what `nutrition_screen`
/// shows inline for *today*, parameterized to any date. Reached by tapping
/// a day on the nutrition week strip.
class NutritionDayScreen extends StatelessWidget {
  final DateTime date;

  const NutritionDayScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<NutritionRepository>();
    final entries = repo.entriesForDate(date);
    final totals = repo.totalsForDate(date);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(DateFormat.yMMMd().format(date))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _MacroStat(
                        label: 'kcal',
                        value: totals.calories.toStringAsFixed(0)),
                    _MacroStat(
                        label: 'Protein',
                        value: '${totals.proteinG.toStringAsFixed(0)}g'),
                    _MacroStat(
                        label: 'Carbs',
                        value: '${totals.carbsG.toStringAsFixed(0)}g'),
                    _MacroStat(
                        label: 'Fat',
                        value: '${totals.fatG.toStringAsFixed(0)}g'),
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
                    Icon(Icons.restaurant,
                        size: 40, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      'Nothing logged this day',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              )
            else
              for (final entry in entries) _DayFoodTile(entry: entry),
          ],
        ),
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  final String label;
  final String value;

  const _MacroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _DayFoodTile extends StatelessWidget {
  final FoodEntry entry;

  const _DayFoodTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final grams = entry.grams;
    final title = grams != null
        ? '${entry.name} · ${grams.toStringAsFixed(0)}g'
        : entry.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () => showFoodEntryDetailSheet(context, entry),
          title: Text(title),
          subtitle: Text(
            '${entry.mealType.label} · P${entry.proteinG.toStringAsFixed(0)} '
            'C${entry.carbsG.toStringAsFixed(0)} F${entry.fatG.toStringAsFixed(0)}',
          ),
          trailing: Text(
            '${entry.calories.toStringAsFixed(0)} kcal',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
