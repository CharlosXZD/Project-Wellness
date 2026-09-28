import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/cycle/cycle_calculator.dart';
import '../../core/nutrition/intake_stats.dart';
import '../../core/theme/app_theme.dart';
import '../../core/units/units.dart';
import '../../models/weight_entry.dart';
import '../../models/workout_session.dart';
import '../../repositories/cycle_repository.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/macro_bar.dart';
import '../nutrition/nutrition_day_screen.dart';
import '../training/log_weight_sheet.dart';
import '../training/session_detail_screen.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Full month-by-month calendar behind the 7-day strips — every day's food,
/// workouts, weigh-ins (and period days, with cycle tracking on) at a
/// glance, with a detail panel for the selected day.
class CalendarScreen extends StatefulWidget {
  final DateTime? initialDate;

  const CalendarScreen({super.key, this.initialDate});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _firstMonth;
  late final DateTime _lastMonth;
  late final PageController _pageController;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _lastMonth = DateTime(now.year, now.month);
    final training = context.read<TrainingRepository>();
    final nutrition = context.read<NutritionRepository>();
    final firstUse = firstUseDate(
      profile: context.read<ProfileRepository>().profile,
      foodEntries: nutrition.entries,
      weightEntries: training.weightEntries,
      sessions: training.sessions,
    );
    _firstMonth = DateTime(firstUse.year, firstUse.month);
    _selected = _dateOnly(widget.initialDate ?? now);
    final selectedMonth = DateTime(_selected.year, _selected.month);
    if (selectedMonth.isBefore(_firstMonth)) _firstMonth = selectedMonth;
    _pageController = PageController(initialPage: _monthIndex(selectedMonth));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _monthCount =>
      (_lastMonth.year - _firstMonth.year) * 12 + _lastMonth.month - _firstMonth.month + 1;

  int _monthIndex(DateTime month) =>
      (month.year - _firstMonth.year) * 12 + month.month - _firstMonth.month;

  DateTime _monthAt(int index) => DateTime(_firstMonth.year, _firstMonth.month + index);

  void _goToMonth(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = context.watch<NutritionRepository>();
    final training = context.watch<TrainingRepository>();
    final cycle = context.watch<CycleRepository>();
    final settings = context.watch<SettingsRepository>();

    final foodDays = <DateTime>{for (final e in nutrition.entries) _dateOnly(e.date)};
    final workoutDays = <DateTime>{for (final s in training.sessions) _dateOnly(s.date)};
    final weighInDays = <DateTime>{for (final w in training.weightEntries) _dateOnly(w.date)};
    final periodStarts = settings.cycleTrackingEnabled
        ? cycle.entries.map((e) => e.date).toList()
        : const <DateTime>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selected = _dateOnly(DateTime.now()));
              _goToMonth(_monthCount - 1);
            },
            child: const Text('Today'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            SizedBox(
              height: 372,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _monthCount,
                itemBuilder: (context, index) {
                  final month = _monthAt(index);
                  return _MonthView(
                    month: month,
                    selected: _selected,
                    canGoBack: index > 0,
                    canGoForward: index < _monthCount - 1,
                    onBack: () => _goToMonth(index - 1),
                    onForward: () => _goToMonth(index + 1),
                    onSelect: (day) => setState(() => _selected = day),
                    hasFood: foodDays.contains,
                    hasWorkout: workoutDays.contains,
                    hasWeighIn: weighInDays.contains,
                    isPeriodDay: (day) => isLoggedPeriodDay(periodStarts, day),
                  );
                },
              ),
            ),
            _Legend(showPeriod: settings.cycleTrackingEnabled),
            const SizedBox(height: 16),
            _DayDetail(day: _selected),
          ],
        ),
      ),
    );
  }
}

class _MonthView extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final ValueChanged<DateTime> onSelect;
  final bool Function(DateTime) hasFood;
  final bool Function(DateTime) hasWorkout;
  final bool Function(DateTime) hasWeighIn;
  final bool Function(DateTime) isPeriodDay;

  const _MonthView({
    required this.month,
    required this.selected,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    required this.onSelect,
    required this.hasFood,
    required this.hasWorkout,
    required this.hasWeighIn,
    required this.isPeriodDay,
  });

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final today = _dateOnly(DateTime.now());
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday - 1;
    final cellCount = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: canGoBack ? onBack : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM().format(month),
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: canGoForward ? onForward : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final letter in _weekdayLetters)
              Expanded(
                child: Text(
                  letter,
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 48,
            ),
            itemCount: cellCount,
            itemBuilder: (context, index) {
              final dayNumber = index - leadingBlanks + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox.shrink();
              final day = DateTime(month.year, month.month, dayNumber);
              final isFuture = day.isAfter(today);
              final isSelected = DateUtils.isSameDay(day, selected);
              final isToday = DateUtils.isSameDay(day, today);
              final period = isPeriodDay(day);

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isFuture ? null : () => onSelect(day),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? scheme.primary
                            : period
                                ? AppColors.cycle.withValues(alpha: 0.22)
                                : null,
                        border: isToday && !isSelected ? Border.all(color: scheme.primary, width: 1.5) : null,
                      ),
                      child: Text(
                        '$dayNumber',
                        style: textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? scheme.onPrimary
                              : isFuture
                                  ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
                                  : scheme.onSurface,
                          fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dot(visible: hasFood(day), color: AppColors.nutrition),
                        _Dot(visible: hasWorkout(day), color: AppColors.training),
                        _Dot(visible: hasWeighIn(day), color: scheme.tertiary),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool visible;
  final Color color;

  const _Dot({required this.visible, required this.color});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Legend extends StatelessWidget {
  final bool showPeriod;

  const _Legend({required this.showPeriod});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 6,
      children: [
        item(AppColors.nutrition, 'Food'),
        item(AppColors.training, 'Workout'),
        item(scheme.tertiary, 'Weigh-in'),
        if (showPeriod) item(AppColors.cycle.withValues(alpha: 0.5), 'Period'),
      ],
    );
  }
}

/// Everything logged on [day], with shortcuts into each area.
class _DayDetail extends StatelessWidget {
  final DateTime day;

  const _DayDetail({required this.day});

  @override
  Widget build(BuildContext context) {
    final nutrition = context.watch<NutritionRepository>();
    final training = context.watch<TrainingRepository>();
    final unitSystem = context.watch<SettingsRepository>().unitSystem;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final totals = nutrition.totalsForDate(day);
    final foodCount = nutrition.entriesForDate(day).length;
    final sessions = training.sessions.where((s) => DateUtils.isSameDay(s.date, day)).toList();
    final weighIns = training.weightEntries.where((w) => DateUtils.isSameDay(w.date, day)).toList();
    final isToday = DateUtils.isSameDay(day, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isToday ? 'Today' : DateFormat.yMMMMEEEEd().format(day),
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => NutritionDayScreen(date: day)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _SectionIcon(icon: Icons.restaurant, color: AppColors.nutrition),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Food', style: textTheme.titleSmall),
                            Text(
                              foodCount == 0
                                  ? 'Nothing logged'
                                  : '${totals.calories.round()} kcal · $foodCount ${foodCount == 1 ? 'item' : 'items'}',
                              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                    ],
                  ),
                  if (foodCount > 0) ...[
                    const SizedBox(height: 14),
                    MacroBar(proteinG: totals.proteinG, carbsG: totals.carbsG, fatG: totals.fatG),
                    const SizedBox(height: 10),
                    MacroLegendRow(proteinG: totals.proteinG, carbsG: totals.carbsG, fatG: totals.fatG),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (sessions.isEmpty)
                const ListTile(
                  leading: _SectionIcon(icon: Icons.fitness_center, color: AppColors.training),
                  title: Text('Workout'),
                  subtitle: Text('Rest day'),
                )
              else
                for (final session in sessions) _SessionRow(session: session),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (weighIns.isEmpty)
                ListTile(
                  leading: _SectionIcon(icon: Icons.monitor_weight_outlined, color: scheme.tertiary),
                  title: const Text('Weight'),
                  subtitle: const Text('No weigh-in'),
                )
              else
                for (final entry in weighIns) _WeighInRow(entry: entry, unitSystem: unitSystem),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  final WorkoutSession session;

  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final minutes = session.durationMinutes;
    return ListTile(
      leading: const _SectionIcon(icon: Icons.fitness_center, color: AppColors.training),
      title: Text(session.name),
      subtitle: Text([
        session.dayName,
        '${session.exercises.length} exercises',
        if (minutes != null) '$minutes min',
      ].join(' · ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SessionDetailScreen(session: session)),
      ),
    );
  }
}

class _WeighInRow extends StatelessWidget {
  final WeightEntry entry;
  final UnitSystem unitSystem;

  const _WeighInRow({required this.entry, required this.unitSystem});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _SectionIcon(icon: Icons.monitor_weight_outlined, color: Theme.of(context).colorScheme.tertiary),
      title: Text(Units.formatWeight(entry.weightKg, unitSystem)),
      subtitle: Text(entry.note ?? DateFormat.jm().format(entry.date)),
      trailing: const Icon(Icons.edit_outlined, size: 20),
      onTap: () => showLogWeightSheet(context, existing: entry),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SectionIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
