import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/nutrition/bmr_calculator.dart';
import '../../core/nutrition/target_calories.dart';
import '../../core/theme/app_theme.dart';
import '../../models/food_entry.dart';
import '../../models/nutrition_goal.dart';
import '../../models/user_profile.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/activity_week_strip.dart';
import '../../widgets/macro_bar.dart';
import '../../widgets/rect_button.dart';
import '../settings/settings_screen.dart';
import 'add_food_sheet.dart';
import 'food_entry_detail_sheet.dart';
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
  if (DateTime.now().difference(profile.createdAt) < const Duration(days: 10))
    return false;

  final selfReportedHighActivity =
      profile.initialActivityLevel?.isHighActivity ?? false;
  final preciseInput = profile.preciseCalorieTrackingEnabled
      ? profile.preciseActivityInput
      : null;
  final preciseHighActivity =
      (preciseInput?.toActivityLevel().multiplier ?? 0) >= 1.725;

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
    final todayEntries = repo.entriesForDate(today);
    final totals = repo.totalsForDate(today);
    final target = computeTargetCalories(
      profile: profile,
      goal: repo.goal,
      currentWeightKg: training.latestWeightKg ?? profile?.weightKg,
      sessions: training.sessions,
    );

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
                  ),
                  const SizedBox(height: 16),
                  if (showWorkoutNudge) ...[
                    const _WorkoutLoggingNudgeBanner(),
                    const SizedBox(height: 16),
                  ],
                  _SummaryCard(totals: totals, goal: repo.goal, target: target),
                  const SizedBox(height: 28),
                  Text(
                    'Log food',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  RectButton(
                    icon: Icons.search,
                    title: 'Search food',
                    subtitle: 'Pick a food, enter the amount',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const FoodPickerScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RectButton(
                    icon: Icons.qr_code_scanner,
                    title: 'Scan barcode or label',
                    subtitle:
                        'Look it up or read nutrition facts with the camera',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RectButton(
                    icon: Icons.history,
                    title: 'Previously scanned',
                    subtitle: 'Log or save something you\'ve scanned before',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ScannedProductsScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RectButton(
                    icon: Icons.fastfood,
                    title: 'My snacks',
                    subtitle: 'One tap to add a saved snack',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SnacksScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RectButton(
                    icon: Icons.restaurant_menu,
                    title: 'Add meal',
                    subtitle:
                        'Breakfast, lunch, or dinner — build from ingredients',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MealsScreen()),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => showAddFoodSheet(context),
                      child: const Text('Add manually'),
                    ),
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
                    ...todayEntries.map(
                      (entry) => _FoodTile(entry: entry),
                    ),
                ],
              ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final MacroTotals totals;
  final NutritionGoal? goal;
  final TargetCalories? target;

  const _SummaryCard(
      {required this.totals, required this.goal, required this.target});

  @override
  Widget build(BuildContext context) {
    final goal = this.goal;
    final target = this.target;
    final scheme = Theme.of(context).colorScheme;

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
                  Expanded(
                    child: Text('Today',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (target != null)
                    Text(
                      '${(totals.calories / ((target.low + target.high) / 2) * 100).clamp(0, 999).round()}% of goal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.show_chart,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${totals.calories.toStringAsFixed(0)} kcal',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (target != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Goal: ${formatCalorieRange(target.low, target.high)}'
                  '${goal != null && goal.mode != GoalMode.maintain ? ' · ${goal.mode.label}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 20),
              MacroBar(
                proteinG: totals.proteinG,
                carbsG: totals.carbsG,
                fatG: totals.fatG,
              ),
              const SizedBox(height: 16),
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

class _FoodTile extends StatelessWidget {
  final FoodEntry entry;

  const _FoodTile({required this.entry});

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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
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
