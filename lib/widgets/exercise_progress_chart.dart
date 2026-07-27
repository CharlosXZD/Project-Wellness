import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/training/chart_axis.dart';
import '../core/training/exercise_series.dart';
import '../core/units/units.dart';

/// Small embedded line chart of one exercise's top-set weight over time —
/// used on the post-workout summary and workout-details screens. Same
/// `fl_chart` styling as the body-weight trend chart in
/// `weight_history_screen.dart`, scaled down for a card rather than a full
/// screen. Renders nothing when there's fewer than two points to draw a
/// line between.
class ExerciseProgressChart extends StatelessWidget {
  final List<ExerciseWeightPoint> points;
  final UnitSystem unitSystem;

  const ExerciseProgressChart({super.key, required this.points, required this.unitSystem});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final displayWeights = points
        .map((p) => unitSystem == UnitSystem.metric ? p.topWeightKg : Units.kgToLbs(p.topWeightKg))
        .toList();
    var minY = displayWeights.reduce((a, b) => a < b ? a : b);
    var maxY = displayWeights.reduce((a, b) => a > b ? a : b);
    minY = (minY - 2).floorToDouble().clamp(0, double.infinity);
    maxY = (maxY + 2).ceilToDouble();
    if (minY == maxY) maxY += 2;
    // fl_chart's own auto-interval logic (used whenever `interval` is left
    // unset) can pick gridlines that land within a pixel of `maxY` itself,
    // rendering two overlapping labels near the top of the axis. Picking a
    // single explicit, evenly-spaced interval and handing it to both the
    // grid and the labels guarantees they always agree and never crowd.
    final interval = niceAxisInterval((maxY - minY) / 4);
    minY = (minY / interval).floorToDouble() * interval;
    maxY = (maxY / interval).ceilToDouble() * interval;

    final labelStep = (points.length / 4).ceil().clamp(1, points.length);

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: interval),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: interval,
                getTitlesWidget: (value, meta) =>
                    Text(value.toStringAsFixed(0), style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: labelStep.toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat.Md().format(points[index].date),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                return LineTooltipItem(
                  Units.formatWeight(points[spot.x.round()].topWeightKg, unitSystem),
                  Theme.of(context).textTheme.bodySmall!.copyWith(color: scheme.onInverseSurface),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), displayWeights[i])],
              isCurved: true,
              color: scheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: scheme.primary.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}
