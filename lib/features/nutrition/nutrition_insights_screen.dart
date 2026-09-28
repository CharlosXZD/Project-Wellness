import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/nutrition/daily_target_scope.dart';
import '../../core/nutrition/intake_stats.dart';
import '../../core/nutrition/target_calories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/training/chart_axis.dart';
import '../../core/units/units.dart';
import '../../models/nutrition_goal.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/calorie_delta_editor.dart';
import '../../widgets/macro_bar.dart';
import '../../widgets/period_selector.dart';
import 'goals_screen.dart';
import 'nutrition_day_screen.dart';

/// One bar on the calorie chart: a single day (week/month views) or the
/// average of the *logged* days in a week/month (longer views).
class _Bar {
  final DateTime start;
  final double calories;
  final bool isToday;

  /// Days in a bucket that actually had food logged — 0 means no bar.
  final int loggedDays;

  const _Bar({
    required this.start,
    required this.calories,
    required this.loggedDays,
    this.isToday = false,
  });
}

List<_Bar> _buildBars(List<DailyTotal> daily, ChartPeriod period) {
  final today = DateUtils.dateOnly(DateTime.now());
  if (period.isDaily) {
    return [
      for (final d in daily)
        _Bar(
          start: d.date,
          calories: d.totals.calories,
          loggedDays: d.totals.calories > 0 ? 1 : 0,
          isToday: DateUtils.isSameDay(d.date, today),
        ),
    ];
  }

  // Weekly buckets for 3 months, calendar months for a year. Today is left
  // out of the averages (it's still being logged).
  final bars = <_Bar>[];
  final byBucket = <DateTime, List<DailyTotal>>{};
  for (final d in daily) {
    if (!d.date.isBefore(today)) continue;
    final key = period == ChartPeriod.threeMonths
        ? d.date.subtract(Duration(days: d.date.weekday - 1))
        : DateTime(d.date.year, d.date.month);
    byBucket.putIfAbsent(key, () => []).add(d);
  }
  for (final entry in byBucket.entries) {
    final logged = entry.value.where((d) => d.totals.calories > 0).toList();
    bars.add(_Bar(
      start: entry.key,
      calories: logged.isEmpty ? 0 : logged.fold(0.0, (s, d) => s + d.totals.calories) / logged.length,
      loggedDays: logged.length,
    ));
  }
  bars.sort((a, b) => a.start.compareTo(b.start));
  return bars;
}

class NutritionInsightsScreen extends StatefulWidget {
  const NutritionInsightsScreen({super.key});

  @override
  State<NutritionInsightsScreen> createState() => _NutritionInsightsScreenState();
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
    final textTheme = Theme.of(context).textTheme;

    final firstUse = firstUseDate(
      profile: profile,
      foodEntries: nutrition.entries,
      weightEntries: training.weightEntries,
    );
    final start = chartRangeStart(days: _period.days, firstUse: firstUse);
    final daily = nutrition.dailyTotalsForRange(start, DateTime.now());
    final bars = _buildBars(daily, _period);
    final stats = IntakeStats.from(daily);
    final todayCalories = nutrition.totalsForDate(DateTime.now()).calories;

    final target = watchDailyTarget(context);
    final goalTargetWeight = nutrition.goal?.targetWeightKg;
    final atTargetWeight = goalTargetWeight == null
        ? null
        : watchDailyTarget(context, weightKg: goalTargetWeight);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition insights'),
        actions: [
          IconButton(
            tooltip: 'Goals & BMR',
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GoalsScreen()),
            ),
          ),
        ],
      ),
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
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily average', style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                    Text(
                      stats.loggedDays == 0 ? 'No completed days yet' : '${stats.avgCalories.round()} kcal',
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        '${stats.loggedDays} of ${stats.completedDays} days logged',
                        if (target != null && stats.loggedDays > 0) _vsTarget(stats.avgCalories, target.kcal),
                      ].join(' · '),
                      style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 220,
                      child: bars.every((b) => b.loggedDays == 0)
                          ? Center(
                              child: Text(
                                'Nothing logged in this period yet',
                                style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            )
                          : _CalorieBarChart(
                              bars: bars,
                              targetKcal: target?.kcal,
                              period: _period,
                              onDayTap: _period.isDaily
                                  ? (day) => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => NutritionDayScreen(date: day)),
                                      )
                                  : null,
                            ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        if (target != null)
                          _LegendItem(
                            color: scheme.tertiary,
                            dashed: true,
                            label: "Today's target ${formatKcal(target.kcal)}",
                          ),
                        if (_period.isDaily && todayCalories > 0)
                          _LegendItem(
                            color: AppColors.nutrition.withValues(alpha: 0.4),
                            label: 'Today so far (not in average)',
                          ),
                        if (!_period.isDaily)
                          Text(
                            'Each bar averages the logged days in that ${_period == ChartPeriod.threeMonths ? 'week' : 'month'}',
                            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Average macros', style: textTheme.titleMedium),
                    const SizedBox(height: 16),
                    MacroBar(proteinG: stats.avgProteinG, carbsG: stats.avgCarbsG, fatG: stats.avgFatG),
                    const SizedBox(height: 16),
                    MacroLegendRow(proteinG: stats.avgProteinG, carbsG: stats.avgCarbsG, fatG: stats.avgFatG),
                    if (stats.loggedDays > 0 && target != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${(stats.avgProteinG / target.weightKg).toStringAsFixed(1)} g protein per kg of body weight',
                        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your goal', style: textTheme.titleMedium),
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
            if (atTargetWeight != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Maintenance at your target weight', style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('≈ ${formatKcal(atTargetWeight.maintenanceKcal)}/day', style: textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Roughly what you\'d eat to stay at '
                        '${Units.formatWeight(goalTargetWeight!, unitSystem)} once you get there.',
                        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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

String _vsTarget(double avg, double target) {
  final diff = avg - target;
  if (diff.abs() < 25) return 'right on target';
  return '${diff.abs().round()} ${diff < 0 ? 'under' : 'over'} target';
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendItem({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dashed
            ? Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(width: 4, height: 2, margin: const EdgeInsets.only(right: 2), color: color),
                ],
              )
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _CalorieBarChart extends StatelessWidget {
  final List<_Bar> bars;
  final double? targetKcal;
  final ChartPeriod period;
  final ValueChanged<DateTime>? onDayTap;

  const _CalorieBarChart({
    required this.bars,
    required this.targetKcal,
    required this.period,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    var maxY = bars.fold(0.0, (m, b) => b.calories > m ? b.calories : m);
    if (targetKcal != null && targetKcal! > maxY) maxY = targetKcal!;
    final interval = niceAxisInterval(maxY / 4);
    maxY = ((maxY * 1.08) / interval).ceilToDouble() * interval;

    final barWidth = switch (bars.length) {
      <= 7 => 22.0,
      <= 14 => 14.0,
      <= 31 => 7.0,
      _ => 12.0,
    };
    final labelEvery = (bars.length / 6).ceil().clamp(1, bars.length);
    final dateFormat = switch (period) {
      ChartPeriod.week => DateFormat.E(),
      ChartPeriod.year => DateFormat.MMM(),
      _ => DateFormat.Md(),
    };

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
        ),
        extraLinesData: targetKcal == null
            ? const ExtraLinesData()
            : ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: targetKcal!,
                  color: scheme.tertiary,
                  strokeWidth: 1.5,
                  dashArray: [6, 4],
                ),
              ]),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Text(
                  value >= 1000 ? '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k' : value.round().toString(),
                  style: textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                // Label from the newest bar backwards so today/this week
                // always gets one.
                if ((bars.length - 1 - i) % labelEvery != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(dateFormat.format(bars[i].start), style: textTheme.bodySmall),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchCallback: onDayTap == null
              ? null
              : (event, response) {
                  if (event is! FlTapUpEvent) return;
                  final i = response?.spot?.touchedBarGroupIndex;
                  if (i != null && bars[i].loggedDays > 0) onDayTap!(bars[i].start);
                },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final bar = bars[groupIndex];
              if (bar.loggedDays == 0) return null;
              final label = period.isDaily
                  ? DateFormat.MMMEd().format(bar.start)
                  : period == ChartPeriod.threeMonths
                      ? 'Week of ${DateFormat.MMMd().format(bar.start)}'
                      : DateFormat.yMMMM().format(bar.start);
              return BarTooltipItem(
                '${bar.calories.round()} kcal\n',
                textTheme.bodySmall!.copyWith(color: scheme.onInverseSurface, fontWeight: FontWeight.w700),
                children: [
                  TextSpan(
                    text: period.isDaily ? label : '$label · ${bar.loggedDays} days',
                    style: textTheme.labelSmall!.copyWith(color: scheme.onInverseSurface),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < bars.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: bars[i].calories,
                  width: barWidth,
                  color: AppColors.nutrition.withValues(alpha: bars[i].isToday ? 0.4 : 1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(barWidth / 3)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
