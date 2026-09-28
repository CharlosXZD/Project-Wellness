import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/nutrition/bmr_calculator.dart';
import '../../core/nutrition/daily_target_scope.dart';
import '../../core/nutrition/target_calories.dart';
import '../../core/theme/app_theme.dart';
import '../../models/food_entry.dart';
import '../../models/nutrition_goal.dart';
import '../../models/user_profile.dart';
import '../calendar/calendar_screen.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/activity_week_strip.dart';
import '../../widgets/calorie_ring.dart';
import '../../widgets/macro_bar.dart';
import '../settings/settings_screen.dart';
import 'add_food_sheet.dart';
import 'food_picker_screen.dart';
import 'goals_screen.dart';
import 'meals_screen.dart';
import 'nutrition_day_screen.dart';
import 'nutrition_insights_screen.dart';
import 'scan_screen.dart';
import 'scanned_products_screen.dart';
import 'snacks_screen.dart';
import 'supplements_screen.dart';

/// Whether [profile] reports being very active but has barely logged any
/// workouts in this app recently, ~10 days into using it — worth asking if
/// they're training somewhere this app doesn't see, since that mismatch
/// otherwise silently produces a too-low calorie estimate.
bool _shouldShowWorkoutNudge(UserProfile? profile, int sessionsLast7Days) {
  if (profile == null || profile.workoutLoggingNudgeDismissed) return false;
  if (sessionsLast7Days > 1) return false;
  if (DateTime.now().difference(profile.createdAt) < const Duration(days: 10)) {
    return false;
  }

  final selfReportedHighActivity =
      profile.initialActivityLevel?.isHighActivity ?? false;
  final preciseInput = profile.preciseCalorieTrackingEnabled
      ? profile.preciseActivityInput
      : null;
  final preciseHighActivity = (preciseInput?.exerciseDaysPerWeek ?? 0) >= 5;

  return selfReportedHighActivity || preciseHighActivity;
}

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<NutritionRepository>();
    final profile = context.watch<ProfileRepository>().profile;
    final training = context.watch<TrainingRepository>();
    final today = DateTime.now();
    final todayEntries = repo.entriesForDate(today)
      ..sort((a, b) => a.date.compareTo(b.date));
    final totals = repo.totalsForDate(today);
    final target = watchDailyTarget(context);

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final sessionsLast7Days =
        training.sessions.where((s) => s.date.isAfter(weekAgo)).length;
    final showWorkoutNudge =
        _shouldShowWorkoutNudge(profile, sessionsLast7Days);

    final weekDays = [
      for (final date in lastSevenDays())
        ActivityDay(
            date: date, primaryActive: repo.entriesForDate(date).isNotEmpty),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            tooltip: 'Goals & BMR',
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GoalsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Supplements',
            icon: const Icon(Icons.medication_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SupplementsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: !repo.isLoaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  ActivityWeekStrip(
                    days: weekDays,
                    primaryColor: AppColors.nutrition,
                    onDayTap: (date) => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => NutritionDayScreen(date: date)),
                    ),
                    onOpenCalendar: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (showWorkoutNudge) ...[
                    const _WorkoutLoggingNudgeBanner(),
                    const SizedBox(height: 16),
                  ],
                  _SummaryCard(totals: totals, target: target),
                  const SizedBox(height: 28),
                  Text(
                    'Log food',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.9,
                    children: [
                      _LogTile(
                        icon: Icons.search,
                        title: 'Search food',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const FoodPickerScreen()),
                        ),
                      ),
                      _LogTile(
                        icon: Icons.qr_code_scanner,
                        title: 'Scan',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ScanScreen()),
                        ),
                      ),
                      _LogTile(
                        icon: Icons.fastfood,
                        title: 'My snacks',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SnacksScreen()),
                        ),
                      ),
                      _LogTile(
                        icon: Icons.restaurant_menu,
                        title: 'My meals',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MealsScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ScannedProductsScreen()),
                        ),
                        icon: const Icon(Icons.history, size: 18),
                        label: const Text('Previously scanned'),
                      ),
                      TextButton.icon(
                        onPressed: () => showAddFoodSheet(context),
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text('Add manually'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Today's log",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (todayEntries.isEmpty)
                    const _EmptyState()
                  else
                    for (final meal in MealType.values)
                      if (todayEntries.any((e) => e.mealType == meal))
                        MealGroup(
                          meal: meal,
                          entries: todayEntries
                              .where((e) => e.mealType == meal)
                              .toList(),
                        ),
                ],
              ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final MacroTotals totals;
  final DailyTarget? target;

  const _SummaryCard({required this.totals, required this.target});

  @override
  Widget build(BuildContext context) {
    final target = this.target;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NutritionInsightsScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CalorieRing(
                    eaten: totals.calories,
                    target: target?.kcal,
                    color: AppColors.nutrition,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Eaten',
                            style: textTheme.labelLarge
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                        Text('${totals.calories.round()} kcal',
                            style: textTheme.titleLarge),
                        const SizedBox(height: 10),
                        Text('Goal',
                            style: textTheme.labelLarge
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                        Text(
                          target == null ? 'Set up in Goals' : formatKcal(target.kcal),
                          style: textTheme.titleLarge,
                        ),
                        if (target != null && target.mode != GoalMode.maintain)
                          Text(
                            '${target.mode.label} · ${target.goalAdjustmentKcal.abs().round()} kcal',
                            style: textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 20),
              MacroBar(
                proteinG: totals.proteinG,
                carbsG: totals.carbsG,
                fatG: totals.fatG,
              ),
              const SizedBox(height: 12),
              MacroLegendRow(
                proteinG: totals.proteinG,
                carbsG: totals.carbsG,
                fatG: totals.fatG,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LogTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.nutrition.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.nutrition, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutLoggingNudgeBanner extends StatelessWidget {
  const _WorkoutLoggingNudgeBanner();

  Future<void> _dismiss(BuildContext context) async {
    final repo = context.read<ProfileRepository>();
    final profile = repo.profile;
    if (profile == null) return;
    await repo
        .saveProfile(profile.copyWith(workoutLoggingNudgeDismissed: true));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: scheme.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Are we missing your workouts?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      size: 18, color: scheme.onSecondaryContainer),
                  tooltip: 'Dismiss',
                  onPressed: () => _dismiss(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "You told us you're very active, but there's barely any workout log here. "
              'If you train outside the app, syncing Health data gives a much more accurate '
              'calorie estimate than a self-reported activity level.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _dismiss(context),
                  child: const Text('Keep my answer'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.restaurant,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing logged today',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
