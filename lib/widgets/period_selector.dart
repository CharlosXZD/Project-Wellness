import 'package:flutter/material.dart';

/// Time window for a trend chart. Shared between the calorie history and
/// weight history screens so "week/month/3 months/year" means the same
/// thing everywhere.
enum ChartPeriod { week, month, threeMonths, year }

extension ChartPeriodX on ChartPeriod {
  String get label {
    switch (this) {
      case ChartPeriod.week:
        return 'Week';
      case ChartPeriod.month:
        return 'Month';
      case ChartPeriod.threeMonths:
        return '3 Months';
      case ChartPeriod.year:
        return 'Year';
    }
  }

  int get days {
    switch (this) {
      case ChartPeriod.week:
        return 7;
      case ChartPeriod.month:
        return 30;
      case ChartPeriod.threeMonths:
        return 90;
      case ChartPeriod.year:
        return 365;
    }
  }

  /// Daily granularity is only legible for the shorter windows; longer
  /// windows are bucketed (see `bucketing.dart`) to keep the chart readable.
  bool get isDaily => this == ChartPeriod.week || this == ChartPeriod.month;
}

class PeriodSelector extends StatelessWidget {
  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onChanged;

  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ChartPeriod>(
      segments: ChartPeriod.values
          .map((p) => ButtonSegment(value: p, label: Text(p.label)))
          .toList(),
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
