import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/cycle/cycle_calculator.dart';
import '../../core/nutrition/daily_target_scope.dart';
import '../../core/streak/streak_calculator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/units/units.dart';
import '../../core/widget/home_widget_service.dart';
import '../../data/medal_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../models/workout_session.dart';
import '../../repositories/cycle_repository.dart';
import '../../repositories/health_activity_repository.dart';
import '../../repositories/medals_repository.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/activity_week_strip.dart';
import '../../widgets/calorie_ring.dart';
import '../calendar/calendar_screen.dart';
import '../nutrition/nutrition_day_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../settings/cycle_screen.dart';
import '../settings/settings_screen.dart';
import '../training/body_rank_screen.dart';
import '../training/medals_screen.dart';
import '../training/log_weight_sheet.dart';
import '../training/session_detail_screen.dart';
import '../training/training_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Prefers a logged workout (a specific session to open) over food (no
  /// single "day" screen to open before Nutrition existed one) when a day
  /// has both — see `NutritionDayScreen`/`SessionDetailScreen`.
  void _openDay(
    BuildContext context, {
    required List<WorkoutSession> sessions,
    required DateTime date,
  }) {
    for (final session in sessions) {
      if (isSameDay(session.date, date)) {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => SessionDetailScreen(session: session)),
        );
        return;
      }
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NutritionDayScreen(date: date)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = context.watch<ProfileRepository>().profile;
    final greetingName = profile?.name.split(' ').first ?? '';

    // Keep the home-screen widget's calorie snapshot fresh whenever the user
    // lands back here (e.g. after logging food) — cheap and idempotent.
    final nutrition = context.watch<NutritionRepository>();
    final profileRepo = context.read<ProfileRepository>();
    final training = context.watch<TrainingRepository>();
    final settingsRepo = context.watch<SettingsRepository>();
    final health = context.watch<HealthActivityRepository>().summary;
    final cycleAdjustment = currentCycleAdjustmentKcal(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeWidgetService.instance.syncTodayCalories(
        nutrition: nutrition,
        profile: profileRepo,
        training: training,
        health: health,
        cycleAdjustmentKcal: cycleAdjustment,
      );
    });
    final target = watchDailyTarget(context);
    final unitSystem = settingsRepo.unitSystem;
    final todayTotals = nutrition.totalsForDate(DateTime.now());
    final lastSession = training.sessions.isEmpty ? null : training.sessions.first;
    final latestWeight = training.weightEntries.isEmpty ? null : training.weightEntries.first;
    final cycleStatus = settingsRepo.cycleTrackingEnabled
        ? currentCycleStatus(context.watch<CycleRepository>().entries.map((e) => e.date).toList())
        : null;

    final streak = computeStreak([
      ...nutrition.entries.map((e) => e.date),
      ...training.sessions.map((s) => s.date),
    ]);

    final weekDays = [
      for (final date in lastSevenDays())
        ActivityDay(
          date: date,
          primaryActive: nutrition.entriesForDate(date).isNotEmpty,
          secondaryActive:
              training.sessions.any((s) => isSameDay(s.date, date)),
        ),
    ];

    final medals = context.watch<MedalsRepository>();
    final medalCtx = MedalContext(
      sessions: training.sessions,
      weightEntries: training.weightEntries,
      goalHistory: nutrition.goalHistory,
      nutritionEntries: nutrition.entries,
    );
    MedalDef? nextMedal;
    var nextMedalProgress = 0.0;
    for (final medal in medalCatalog) {
      if (medals.isUnlocked(medal.id)) continue;
      final progress = medal.progress(medalCtx);
      if (progress > nextMedalProgress) {
        nextMedalProgress = progress;
        nextMedal = medal;
      }
    }

    void openNutrition() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NutritionScreen()),
        );
    void openTraining() => Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'training'),
            builder: (_) => const TrainingScreen(),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.greeting(greetingName),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Medals',
                      icon: const Icon(Icons.emoji_events_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MedalsScreen()),
                      ),
                    ),
                    if (medals.hasUnviewed)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  tooltip: l10n.settingsTitle,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            if (streak >= 1 || nextMedal != null) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (streak >= 1)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.streakDays(streak),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  if (nextMedal != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MedalsScreen()),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.military_tech,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${nextMedal.title} · ${(nextMedalProgress * 100).round()}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            ActivityWeekStrip(
              days: weekDays,
              primaryColor: AppColors.nutrition,
              secondaryColor: AppColors.training,
              onDayTap: (date) =>
                  _openDay(context, sessions: training.sessions, date: date),
              onOpenCalendar: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _TodayCard(
              eaten: todayTotals.calories,
              targetKcal: target?.kcal,
              trainedToday: training.sessions.any((s) => isSameDay(s.date, DateTime.now())),
              latestWeight: latestWeight == null
                  ? null
                  : Units.formatWeight(latestWeight.weightKg, unitSystem),
              onNutrition: openNutrition,
              onTraining: openTraining,
              onWeight: () => showLogWeightSheet(context),
            ),
            const SizedBox(height: 16),
            _HomeCard(
              title: l10n.training,
              subtitle: lastSession == null
                  ? l10n.trainingSubtitle
                  : 'Last: ${lastSession.name} · ${_relativeDay(lastSession.date)}',
              icon: Icons.fitness_center,
              color: AppColors.training,
              onTap: openTraining,
            ),
            const SizedBox(height: 12),
            _HomeCard(
              title: l10n.nutrition,
              subtitle: target == null
                  ? l10n.nutritionSubtitle
                  : '${todayTotals.calories.round()} of ${target.kcal.round()} kcal today',
              icon: Icons.restaurant,
              color: AppColors.nutrition,
              onTap: openNutrition,
            ),
            if (settingsRepo.cycleTrackingEnabled) ...[
              const SizedBox(height: 12),
              _HomeCard(
                title: l10n.cycleTracking,
                subtitle: cycleStatus == null
                    ? l10n.cycleTrackingSubtitle
                    : cycleStatus.isLate
                        ? l10n.cyclePeriodLate(cycleStatus.daysLate)
                        : l10n.cycleNextPeriodIn(cycleStatus.daysUntilNextPeriod(DateTime.now())!),
                icon: Icons.calendar_month,
                color: AppColors.cycle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CycleScreen()),
                ),
              ),
            ],
            if (settingsRepo.muscleRankEnabled) ...[
              const SizedBox(height: 12),
              _HomeCard(
                title: 'Body Rank',
                subtitle: 'Your per-muscle rank diagram',
                icon: Icons.accessibility_new,
                color: AppColors.bodyRank,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BodyRankScreen()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _relativeDay(DateTime date) {
  final today = DateUtils.dateOnly(DateTime.now());
  final days = today.difference(DateUtils.dateOnly(date)).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  return '$days days ago';
}

/// Today at a glance: calories left, whether you've trained, latest weight
/// — each part a shortcut into its area.
class _TodayCard extends StatelessWidget {
  final double eaten;
  final double? targetKcal;
  final bool trainedToday;
  final String? latestWeight;
  final VoidCallback onNutrition;
  final VoidCallback onTraining;
  final VoidCallback onWeight;

  const _TodayCard({
    required this.eaten,
    required this.targetKcal,
    required this.trainedToday,
    required this.latestWeight,
    required this.onNutrition,
    required this.onTraining,
    required this.onWeight,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget stat(IconData icon, Color color, String label, String value, VoidCallback onTap) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    Text(value, style: textTheme.titleSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: onNutrition,
              child: CalorieRing(
                eaten: eaten,
                target: targetKcal,
                color: AppColors.nutrition,
                size: 116,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  stat(Icons.restaurant, AppColors.nutrition, 'Eaten',
                      '${eaten.round()}${targetKcal == null ? '' : ' / ${targetKcal!.round()}'} kcal', onNutrition),
                  stat(Icons.fitness_center, AppColors.training, 'Workout',
                      trainedToday ? 'Done today' : 'Not yet', onTraining),
                  stat(Icons.monitor_weight_outlined, scheme.tertiary, 'Weight',
                      latestWeight ?? 'Log a weigh-in', onWeight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
