import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/nutrition/daily_target_scope.dart';
import '../../core/nutrition/intake_stats.dart';
import '../../core/nutrition/target_calories.dart';
import '../../core/training/chart_axis.dart';
import '../../core/training/weight_series.dart';
import '../../core/units/units.dart';
import '../../models/nutrition_goal.dart';
import '../../models/weight_entry.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/period_selector.dart';
import 'log_weight_sheet.dart';

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
    final target = watchDailyTarget(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final firstUse = firstUseDate(
      profile: profile,
      foodEntries: nutrition.entries,
      weightEntries: training.weightEntries,
    );
    final rangeStart = chartRangeStart(days: _period.days, firstUse: firstUse);

    final allPoints = buildWeightSeries(profile: profile, weightEntries: training.weightEntries);
    final rangePoints = allPoints.where((p) => !p.date.isBefore(rangeStart)).toList();
    // Measure the change from the last weigh-in at or before the window
    // opens (when there is one), not just the first one inside it — a
    // single weigh-in this month still shows progress against last month.
    final before = allPoints.where((p) => p.date.isBefore(rangeStart)).toList();
    final reference = before.isNotEmpty ? before.last : (rangePoints.isNotEmpty ? rangePoints.first : null);
    final latest = allPoints.isNotEmpty ? allPoints.last : null;
    final weightDelta = reference != null && latest != null && !identical(reference, latest)
        ? latest.weightKg - reference.weightKg
        : null;
    final chartPoints = [
      if (before.isNotEmpty) before.last,
      ...rangePoints,
    ];

    final stats = IntakeStats.from(nutrition.dailyTotalsForRange(rangeStart, DateTime.now()));
    final targetWeightKg = nutrition.goal?.targetWeightKg;
    final entries = [...training.weightEntries]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: const Text('Weight')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLogWeightSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log weight'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
          children: [
            PeriodSelector(
              selected: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current', style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                              Text(
                                latest == null ? '—' : Units.formatWeight(latest.weightKg, unitSystem),
                                style: textTheme.headlineMedium,
                              ),
                            ],
                          ),
                        ),
                        if (weightDelta != null)
                          _DeltaChip(deltaKg: weightDelta, unitSystem: unitSystem, label: _period.label.toLowerCase()),
                      ],
                    ),
                    if (targetWeightKg != null && latest != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        (targetWeightKg - latest.weightKg).abs() < 0.1
                            ? "You're at your target weight"
                            : '${Units.formatWeight((targetWeightKg - latest.weightKg).abs(), unitSystem)} to go · '
                                'target ${Units.formatWeight(targetWeightKg, unitSystem)}',
                        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 220,
                      child: chartPoints.length < 2
                          ? Center(
                              child: Text(
                                'Log a couple of weigh-ins to see your trend',
                                style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            )
                          : WeightTrendChart(
                              points: chartPoints,
                              rangeStart: rangeStart,
                              targetWeightKg: targetWeightKg,
                              unitSystem: unitSystem,
                            ),
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
                    Text('Nutrition vs. weight', style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'Average intake',
                      value: stats.loggedDays == 0 ? '—' : '${stats.avgCalories.round()} kcal/day',
                    ),
                    if (target != null)
                      _StatRow(
                        label: "Today's ${target.mode == GoalMode.maintain ? 'maintenance' : target.mode.label.toLowerCase()} target",
                        value: formatKcal(target.kcal),
                      ),
                    if (target?.measured != null)
                      _StatRow(
                        label: 'Measured maintenance',
                        value: formatKcal(target!.measured!.tdee),
                      ),
                    _StatRow(
                      label: 'Days logged',
                      value: '${stats.loggedDays} of ${stats.completedDays}',
                    ),
                    const Divider(height: 28),
                    Text(
                      _correlationMessage(
                        mode: nutrition.goal?.mode ?? GoalMode.maintain,
                        weightDeltaKg: weightDelta,
                        hasTarget: target != null,
                        loggedDays: stats.loggedDays,
                        unitSystem: unitSystem,
                      ),
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Weigh-ins', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Tap to edit · swipe to delete',
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No weigh-ins yet',
                      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      _WeighInTile(
                        entry: entries[i],
                        previous: i + 1 < entries.length ? entries[i + 1] : null,
                        unitSystem: unitSystem,
                      ),
                  ],
                ),
              ),
            if (profile != null) ...[
              const SizedBox(height: 12),
              Text(
                'Starting weight ${Units.formatWeight(profile.weightKg, unitSystem)} · '
                '${DateFormat.yMMMd().format(profile.createdAt)}',
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final double deltaKg;
  final UnitSystem unitSystem;
  final String label;

  const _DeltaChip({required this.deltaKg, required this.unitSystem, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final down = deltaKg <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(down ? Icons.south_east : Icons.north_east, size: 16, color: scheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            '${down ? '−' : '+'}${Units.formatWeight(deltaKg.abs(), unitSystem)} · $label',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}

class _WeighInTile extends StatelessWidget {
  final WeightEntry entry;
  final WeightEntry? previous;
  final UnitSystem unitSystem;

  const _WeighInTile({required this.entry, required this.previous, required this.unitSystem});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final previous = this.previous;
    final change = previous == null ? null : entry.weightKg - previous.weightKg;
    final subtitle = [
      DateFormat.yMMMEd().format(entry.date),
      if (entry.note != null) entry.note!,
    ].join(' · ');

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      // Delete inside confirmDismiss so the entry is already gone from the
      // repository by the time the Dismissible finishes animating out.
      confirmDismiss: (_) async {
        await deleteWeightEntryWithUndo(context, entry);
        return true;
      },
      child: ListTile(
        onTap: () => showLogWeightSheet(context, existing: entry),
        title: Text(Units.formatWeight(entry.weightKg, unitSystem)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: change == null || change.abs() < 0.05
            ? null
            : Text(
                '${change < 0 ? '−' : '+'}${Units.formatWeight(change.abs(), unitSystem)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
      ),
    );
  }
}

String _correlationMessage({
  required GoalMode mode,
  required double? weightDeltaKg,
  required bool hasTarget,
  required int loggedDays,
  required UnitSystem unitSystem,
}) {
  if (!hasTarget) {
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
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Weight over *real time* — x is days since [rangeStart], so two weigh-ins
/// a month apart are drawn a month apart, not side by side the way an
/// index-based x axis drew them. A point from before the window (the
/// reference the change is measured from) is clipped to the left edge.
class WeightTrendChart extends StatelessWidget {
  final List<WeightPoint> points;
  final DateTime rangeStart;
  final double? targetWeightKg;
  final UnitSystem unitSystem;
  final bool compact;

  const WeightTrendChart({
    super.key,
    required this.points,
    required this.rangeStart,
    required this.unitSystem,
    this.targetWeightKg,
    this.compact = false,
  });

  double _display(double kg) => unitSystem == UnitSystem.metric ? kg : Units.kgToLbs(kg);

  double _x(DateTime date) => date.difference(rangeStart).inMinutes / (60 * 24);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final maxX = _x(today).ceilToDouble().clamp(1.0, double.infinity);

    // Interpolate the pre-window reference point onto x = 0 so the line
    // enters from the left edge instead of starting off-chart.
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final x = _x(points[i].date);
      final y = _display(points[i].weightKg);
      if (x < 0) {
        if (i + 1 < points.length) {
          final nx = _x(points[i + 1].date);
          final ny = _display(points[i + 1].weightKg);
          final t = nx == x ? 1.0 : (0 - x) / (nx - x);
          spots.add(FlSpot(0, y + (ny - y) * t));
        }
        continue;
      }
      spots.add(FlSpot(x, y));
    }

    final values = spots.map((s) => s.y).toList();
    final target = targetWeightKg == null ? null : _display(targetWeightKg!);
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    // Only pull the target into view when it's reasonably close, or it
    // flattens the actual trend into a line.
    if (target != null && (target - minY).abs() <= (maxY - minY) + 5) {
      minY = minY < target ? minY : target;
      maxY = maxY > target ? maxY : target;
    }
    minY = (minY - 1).floorToDouble();
    maxY = (maxY + 1).ceilToDouble();
    final interval = niceAxisInterval((maxY - minY) / 4);
    minY = (minY / interval).floorToDouble() * interval;
    maxY = (maxY / interval).ceilToDouble() * interval;
    if (maxY <= minY) maxY = minY + interval;

    final dateFormat = maxX > 120 ? DateFormat.MMM() : DateFormat.MMMd();
    final xInterval = (maxX / 4).ceilToDouble().clamp(1.0, double.infinity);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: !compact,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: compact
            ? const FlTitlesData(show: false)
            : FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min) return const SizedBox.shrink();
                      return Text(Units.formatNumber(value), style: Theme.of(context).textTheme.bodySmall);
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: xInterval,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max && value - (meta.max - xInterval) < xInterval * 0.6) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          dateFormat.format(rangeStart.add(Duration(days: value.round()))),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
        extraLinesData: target == null || target < minY || target > maxY
            ? const ExtraLinesData()
            : ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: target,
                    color: scheme.tertiary.withValues(alpha: 0.8),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: !compact,
                      alignment: Alignment.topRight,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.tertiary),
                      labelResolver: (_) => 'Target',
                    ),
                  ),
                ],
              ),
        lineTouchData: LineTouchData(
          enabled: !compact,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems: (touched) => touched.map((spot) {
              final date = rangeStart.add(Duration(minutes: (spot.x * 24 * 60).round()));
              return LineTooltipItem(
                '${Units.formatNumber(spot.y)} ${Units.weightUnitLabel(unitSystem)}\n',
                Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.w700,
                    ),
                children: [
                  TextSpan(
                    text: DateFormat.MMMd().format(date),
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: scheme.onInverseSurface),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: scheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: !compact && spots.length <= 31,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3.5,
                color: scheme.surface,
                strokeWidth: 2.5,
                strokeColor: scheme.primary,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [scheme.primary.withValues(alpha: 0.22), scheme.primary.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
