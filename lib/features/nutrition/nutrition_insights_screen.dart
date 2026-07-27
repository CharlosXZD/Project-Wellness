import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/nutrition/target_calories.dart';
import '../../core/units/units.dart';
import '../../models/nutrition_goal.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/calorie_delta_editor.dart';
import '../../widgets/macro_bar.dart';
import '../../widgets/period_selector.dart';

class _Bucket {
  final DateTime date;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const _Bucket({
    required this.date,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

List<_Bucket> _buildBuckets(List<DailyTotal> daily, ChartPeriod period) {
  if (period.isDaily) {
    return daily
        .map((d) => _Bucket(
              date: d.date,
              calories: d.totals.calories,
              proteinG: d.totals.proteinG,
              carbsG: d.totals.carbsG,
              fatG: d.totals.fatG,
            ))
        .toList();
  }

  final bucketSize = period == ChartPeriod.threeMonths ? 7 : 30;
  final buckets = <_Bucket>[];
  for (var i = 0; i < daily.length; i += bucketSize) {
    final end = (i + bucketSize > daily.length) ? daily.length : i + bucketSize;
    final slice = daily.sublist(i, end);
    final count = slice.length;
    buckets.add(_Bucket(
      date: slice.last.date,
      calories: slice.fold(0.0, (s, d) => s + d.totals.calories) / count,
      proteinG: slice.fold(0.0, (s, d) => s + d.totals.proteinG) / count,
      carbsG: slice.fold(0.0, (s, d) => s + d.totals.carbsG) / count,
      fatG: slice.fold(0.0, (s, d) => s + d.totals.fatG) / count,
    ));
  }
  return buckets;
}

class NutritionInsightsScreen extends StatefulWidget {
  const NutritionInsightsScreen({super.key});

  @override
  State<NutritionInsightsScreen> createState() =>
      _NutritionInsightsScreenState();
}

class _NutritionInsightsScreenState extends State<NutritionInsightsScreen> {
  ChartPeriod _period = ChartPeriod.week;
  late GoalMode _mode;
  late GoalIntensity _intensity;
  double? _customCalorieDelta;
  double? _targetWeightKg;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final goal = context.read<NutritionRepository>().goal;
    _mode = goal?.mode ?? GoalMode.maintain;
    _intensity = goal?.intensity ?? GoalIntensity.moderate;
    _customCalorieDelta = goal?.customCalorieDelta;
    _targetWeightKg = goal?.targetWeightKg;
  }

  Future<void> _saveGoal() async {
    await context.read<NutritionRepository>().saveGoal(
          NutritionGoal(
            mode: _mode,
            intensity: _intensity,
            customCalorieDelta: _customCalorieDelta,
            targetWeightKg: _targetWeightKg,
            updatedAt: DateTime.now(),
          ),
        );
    if (mounted) setState(() => _dirty = false);
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = context.watch<NutritionRepository>();
    final profile = context.watch<ProfileRepository>().profile;
    final training = context.watch<TrainingRepository>();
    final unitSystem = context.watch<SettingsRepository>().unitSystem;
    final scheme = Theme.of(context).colorScheme;

    final end = DateTime.now();
    final start = end.subtract(Duration(days: _period.days - 1));
    final daily = nutrition.dailyTotalsForRange(start, end);
    final buckets = _buildBuckets(daily, _period);

    final target = computeTargetCalories(
      profile: profile,
      goal: nutrition.goal,
      currentWeightKg: training.latestWeightKg ?? profile?.weightKg,
      sessions: training.sessions,
    );

    final recommendedAtTargetWeight = recommendedCaloriesAtTargetWeight(
      profile: profile,
      goal: nutrition.goal,
      sessions: training.sessions,
    );

    final loggedDays = daily.where((d) => d.totals.calories > 0).length;
    final avgCalories = daily.isEmpty
        ? 0.0
        : daily.fold(0.0, (s, d) => s + d.totals.calories) / daily.length;
    final avgProtein = daily.isEmpty
        ? 0.0
        : daily.fold(0.0, (s, d) => s + d.totals.proteinG) / daily.length;
    final avgCarbs = daily.isEmpty
        ? 0.0
        : daily.fold(0.0, (s, d) => s + d.totals.carbsG) / daily.length;
    final avgFat = daily.isEmpty
        ? 0.0
        : daily.fold(0.0, (s, d) => s + d.totals.fatG) / daily.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Insights')),
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
                    Text(
                      'Average ${avgCalories.toStringAsFixed(0)} kcal/day',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$loggedDays of ${daily.length} days logged',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: buckets.length < 2
                          ? const Center(child: Text('Not enough data yet'))
                          : _CalorieChart(
                              buckets: buckets,
                              target: target,
                              mode: nutrition.goal?.mode ?? GoalMode.maintain,
                              period: _period,
                            ),
                    ),
                    if (target != null) ...[
                      const SizedBox(height: 12),
                      _TargetLegend(goal: nutrition.goal, target: target),
                    ],
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
                    Text('Average macros',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    MacroBar(
                        proteinG: avgProtein, carbsG: avgCarbs, fatG: avgFat),
                    const SizedBox(height: 16),
                    MacroLegendRow(
                        proteinG: avgProtein, carbsG: avgCarbs, fatG: avgFat),
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
                    Text('Your goal',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    CalorieDeltaEditor(
                      mode: _mode,
                      intensity: _intensity,
                      customCalorieDelta: _customCalorieDelta,
                      onModeChanged: (mode) => setState(() {
                        _mode = mode;
                        _dirty = true;
                      }),
                      onIntensityChanged: (intensity) => setState(() {
                        _intensity = intensity;
                        _dirty = true;
                      }),
                      onCustomCalorieDeltaChanged: (delta) => setState(() {
                        _customCalorieDelta = delta;
                        _dirty = true;
                      }),
                    ),
                    if (_dirty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saveGoal,
                          child: const Text('Save goal'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (recommendedAtTargetWeight != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommendation at your target weight',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '≈ ${recommendedAtTargetWeight.round()} kcal/day',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estimated maintenance calories once you reach '
                        '${Units.formatWeight(nutrition.goal!.targetWeightKg!, unitSystem)} — '
                        "a directional recommendation, not an exact target.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TargetLegend extends StatelessWidget {
  final NutritionGoal? goal;
  final TargetCalories target;

  const _TargetLegend({required this.goal, required this.target});

  @override
  Widget build(BuildContext context) {
    final mode = goal?.mode ?? GoalMode.maintain;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _bandColor(mode).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${mode.label} target: ${formatCalorieRange(target.low, target.high)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

Color _bandColor(GoalMode mode) {
  switch (mode) {
    case GoalMode.deficit:
      return Colors.blue;
    case GoalMode.surplus:
      return Colors.orange;
    case GoalMode.maintain:
      return Colors.grey;
  }
}

class _CalorieChart extends StatelessWidget {
  final List<_Bucket> buckets;
  final TargetCalories? target;
  final GoalMode mode;
  final ChartPeriod period;

  const _CalorieChart({
    required this.buckets,
    required this.target,
    required this.mode,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final values = buckets.map((b) => b.calories).toList();
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    final target = this.target;
    if (target != null) {
      minY = minY < target.low ? minY : target.low;
      maxY = maxY > target.high ? maxY : target.high;
    }
    minY = (minY * 0.9).floorToDouble();
    if (minY < 0) minY = 0;
    maxY = (maxY * 1.1).ceilToDouble();
    if (maxY <= minY) maxY = minY + 500;

    final labelStep = (buckets.length / 5).ceil().clamp(1, buckets.length);
    final dateFormat = period.isDaily ? DateFormat.Md() : DateFormat.MMMd();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                value.round().toString(),
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
                if (index < 0 || index >= buckets.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    dateFormat.format(buckets[index].date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        rangeAnnotations: target == null
            ? const RangeAnnotations()
            : RangeAnnotations(
                horizontalRangeAnnotations: [
                  HorizontalRangeAnnotation(
                    y1: target.low,
                    y2: target.high,
                    color: _bandColor(mode).withValues(alpha: 0.14),
                  ),
                ],
              ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final bucket = buckets[spot.x.round()];
              return LineTooltipItem(
                '${bucket.calories.round()} kcal',
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
              for (var i = 0; i < buckets.length; i++)
                FlSpot(i.toDouble(), buckets[i].calories),
            ],
            isCurved: true,
            color: scheme.primary,
            barWidth: 3,
            dotData: FlDotData(show: buckets.length <= 14),
            belowBarData: BarAreaData(
                show: true, color: scheme.primary.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}
