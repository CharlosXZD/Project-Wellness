import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/nutrition/target_calories.dart';
import '../../core/training/chart_axis.dart';
import '../../core/training/weight_series.dart';
import '../../core/units/units.dart';
import '../../models/nutrition_goal.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/period_selector.dart';

class WeightHistoryScreen extends StatefulWidget {
  const WeightHistoryScreen({super.key});

  @override
  State<WeightHistoryScreen> createState() => _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends State<WeightHistoryScreen> {
  ChartPeriod _period = ChartPeriod.month;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileRepository>().profile;
    final training = context.watch<TrainingRepository>();
    final nutrition = context.watch<NutritionRepository>();
    final unitSystem = context.watch<SettingsRepository>().unitSystem;
    final scheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final rangeStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: _period.days - 1));

    final allPoints = buildWeightSeries(
        profile: profile, weightEntries: training.weightEntries);
    final rangePoints =
        allPoints.where((p) => !p.date.isBefore(rangeStart)).toList();

    final daily = nutrition.dailyTotalsForRange(rangeStart, now);
    final loggedDays = daily.where((d) => d.totals.calories > 0).length;
    final avgCalories = daily.isEmpty
        ? 0.0
        : daily.fold(0.0, (s, d) => s + d.totals.calories) / daily.length;

    final target = computeTargetCalories(
      profile: profile,
      goal: nutrition.goal,
      currentWeightKg: training.latestWeightKg ?? profile?.weightKg,
      sessions: training.sessions,
    );

    final weightDelta = rangePoints.length >= 2
        ? rangePoints.last.weightKg - rangePoints.first.weightKg
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Weight history')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            PeriodSelector(
              selected: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (weightDelta != null)
                      Row(
                        children: [
                          Icon(
                            weightDelta <= 0
                                ? Icons.trending_down
                                : Icons.trending_up,
                            size: 18,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${Units.formatWeight(weightDelta.abs(), unitSystem)} '
                            '${weightDelta <= 0 ? 'lost' : 'gained'} over ${_period.label.toLowerCase()}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      )
                    else
                      Text('Not enough data yet',
                          style: Theme.of(context).textTheme.titleMedium),
                    if (profile != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Starting weight: ${Units.formatWeight(profile.weightKg, unitSystem)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: rangePoints.length < 2
                          ? const Center(child: Text('Not enough data yet'))
                          : _WeightChart(
                              points: rangePoints,
                              baselineKg: profile?.weightKg,
                              period: _period,
                              unitSystem: unitSystem,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nutrition correlation',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'Average intake',
                      value: '${avgCalories.round()} kcal/day',
                    ),
                    if (target != null)
                      _StatRow(
                        label:
                            '${(nutrition.goal?.mode ?? GoalMode.maintain).label} target',
                        value: formatCalorieRange(target.low, target.high),
                      ),
                    _StatRow(
                      label: 'Days logged',
                      value: '$loggedDays of ${daily.length}',
                    ),
                    const Divider(height: 28),
                    Text(
                      _correlationMessage(
                        mode: nutrition.goal?.mode ?? GoalMode.maintain,
                        weightDeltaKg: weightDelta,
                        target: target,
                        loggedDays: loggedDays,
                        unitSystem: unitSystem,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _correlationMessage({
  required GoalMode mode,
  required double? weightDeltaKg,
  required TargetCalories? target,
  required int loggedDays,
  required UnitSystem unitSystem,
}) {
  if (target == null) {
    return 'Set a nutrition goal (deficit, surplus, or maintain) to see how your eating lines up with your weight trend.';
  }
  if (loggedDays == 0) {
    return "No food logged in this period yet — log meals in Nutrition to see how they line up with your weight trend.";
  }
  if (weightDeltaKg == null) {
    return 'Log a weight entry to compare your trend against your nutrition.';
  }

  final losing = weightDeltaKg < -0.1;
  final gaining = weightDeltaKg > 0.1;
  final deltaText = Units.formatWeight(weightDeltaKg.abs(), unitSystem);

  switch (mode) {
    case GoalMode.deficit:
      if (losing) {
        return "You're in a deficit and down $deltaText — right on track.";
      }
      if (gaining) {
        return "You gained $deltaText despite a deficit goal — worth double-checking your logging or portion sizes.";
      }
      return 'Weight has been steady on your deficit — give it more time, or double check your intake is really below target.';
    case GoalMode.surplus:
      if (gaining) {
        return "You're in a surplus and up $deltaText — right on track for building.";
      }
      if (losing) {
        return "You lost $deltaText despite a surplus goal — you may be under-eating your target.";
      }
      return 'Weight has been steady on your surplus — you may need a bigger surplus to see change.';
    case GoalMode.maintain:
      if (!losing && !gaining) {
        return 'Weight has been stable while maintaining — right on track.';
      }
      return "Weight moved by $deltaText while aiming to maintain — small swings are normal, but keep an eye on the trend.";
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<WeightPoint> points;
  final double? baselineKg;
  final ChartPeriod period;
  final UnitSystem unitSystem;

  const _WeightChart({
    required this.points,
    required this.baselineKg,
    required this.period,
    required this.unitSystem,
  });

  double _displayValue(double kg) =>
      unitSystem == UnitSystem.metric ? kg : Units.kgToLbs(kg);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final values = points.map((p) => _displayValue(p.weightKg)).toList();
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    final baseline = baselineKg == null ? null : _displayValue(baselineKg!);
    if (baseline != null) {
      minY = minY < baseline ? minY : baseline;
      maxY = maxY > baseline ? maxY : baseline;
    }
    minY = (minY - 2).floorToDouble();
    maxY = (maxY + 2).ceilToDouble();
    if (minY == maxY) maxY += 2;
    // See ExerciseProgressChart: an explicit, evenly-spaced interval avoids
    // fl_chart's default auto-interval placing a gridline label right on
    // top of maxY's own label.
    final interval = niceAxisInterval((maxY - minY) / 4);
    minY = (minY / interval).floorToDouble() * interval;
    maxY = (maxY / interval).ceilToDouble() * interval;

    final labelStep = (points.length / 5).ceil().clamp(1, points.length);
    final dateFormat = period.isDaily ? DateFormat.Md() : DateFormat.MMMd();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
            show: true, drawVerticalLine: false, horizontalInterval: interval),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: interval,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: labelStep.toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= points.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    dateFormat.format(points[index].date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        extraLinesData: baseline == null
            ? const ExtraLinesData()
            : ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: baseline,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      labelResolver: (_) => 'Starting weight',
                    ),
                  ),
                ],
              ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final point = points[spot.x.round()];
              return LineTooltipItem(
                Units.formatWeight(point.weightKg, unitSystem),
                Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: scheme.onInverseSurface),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), _displayValue(points[i].weightKg)),
            ],
            isCurved: true,
            color: scheme.primary,
            barWidth: 3,
            dotData: FlDotData(show: points.length <= 14),
            belowBarData: BarAreaData(
                show: true, color: scheme.primary.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}
