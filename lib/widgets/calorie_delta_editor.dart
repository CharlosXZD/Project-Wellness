import 'package:flutter/material.dart';

import '../models/nutrition_goal.dart';

/// Goal mode + calorie delta editor shared by the Goals & BMR screen and
/// the Nutrition Insights screen, so editing your goal in either place
/// behaves identically and can't drift out of sync.
///
/// Below the mode selector, the user either picks a preset intensity chip
/// (mild/moderate/aggressive) or taps "Custom" to enter an exact kcal/day
/// amount (e.g. a 1000 kcal surplus) — the two are mutually exclusive,
/// tracked by whether [customCalorieDelta] is non-null.
class CalorieDeltaEditor extends StatelessWidget {
  final GoalMode mode;
  final GoalIntensity intensity;
  final double? customCalorieDelta;
  final ValueChanged<GoalMode> onModeChanged;
  final ValueChanged<GoalIntensity> onIntensityChanged;
  final ValueChanged<double?> onCustomCalorieDeltaChanged;

  const CalorieDeltaEditor({
    super.key,
    required this.mode,
    required this.intensity,
    required this.customCalorieDelta,
    required this.onModeChanged,
    required this.onIntensityChanged,
    required this.onCustomCalorieDeltaChanged,
  });

  bool get _isCustom => customCalorieDelta != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<GoalMode>(
          segments: GoalMode.values
              .map((m) => ButtonSegment(value: m, label: Text(m.label)))
              .toList(),
          selected: {mode},
          onSelectionChanged: (selection) => onModeChanged(selection.first),
        ),
        if (mode != GoalMode.maintain) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...GoalIntensity.values.map((i) {
                return ChoiceChip(
                  label: Text('${i.label} (${i.calorieDelta} kcal)'),
                  selected: !_isCustom && intensity == i,
                  onSelected: (_) {
                    onIntensityChanged(i);
                    onCustomCalorieDeltaChanged(null);
                  },
                );
              }),
              ChoiceChip(
                label: const Text('Custom'),
                selected: _isCustom,
                onSelected: (_) => onCustomCalorieDeltaChanged(
                  customCalorieDelta ?? intensity.calorieDelta.toDouble(),
                ),
              ),
            ],
          ),
          if (_isCustom) ...[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: customCalorieDelta!.toStringAsFixed(0),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Custom ${mode.label.toLowerCase()} (kcal/day)',
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value.trim());
                if (parsed != null && parsed >= 0) {
                  onCustomCalorieDeltaChanged(parsed);
                }
              },
            ),
          ],
        ],
      ],
    );
  }
}
