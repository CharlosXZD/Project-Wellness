import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/streak/streak_calculator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widget/home_widget_service.dart';
import '../../data/medal_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../models/workout_session.dart';
import '../../repositories/medals_repository.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/activity_week_strip.dart';
import '../nutrition/nutrition_day_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../settings/cycle_screen.dart';
import '../settings/settings_screen.dart';
import '../training/body_rank_screen.dart';
import '../training/medals_screen.dart';
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
    final training = context.read<TrainingRepository>();
    final settingsRepo = context.watch<SettingsRepository>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeWidgetService.instance.syncTodayCalories(
        nutrition: nutrition,
        profile: profileRepo,
        training: training,
        settings: settingsRepo,
      );
    });

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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        tooltip: 'Medals',
                        icon: const Icon(Icons.emoji_events_outlined),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const MedalsScreen()),
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
              Text(
                l10n.greeting(greetingName),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.trackPrompt,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (streak >= 1) ...[
                const SizedBox(height: 12),
                Row(
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
              ],
              if (nextMedal != null) ...[
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MedalsScreen()),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.military_tech,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${nextMedal.title} — ${(nextMedalProgress * 100).round()}% there',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: nextMedalProgress,
                                minHeight: 3,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ActivityWeekStrip(
                days: weekDays,
                primaryColor: AppColors.nutrition,
                secondaryColor: AppColors.training,
                onDayTap: (date) =>
                    _openDay(context, sessions: training.sessions, date: date),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _HomeCard(
                        title: l10n.training,
                        subtitle: l10n.trainingSubtitle,
                        icon: Icons.fitness_center,
                        color: AppColors.training,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            settings: const RouteSettings(name: 'training'),
                            builder: (_) => const TrainingScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _HomeCard(
                        title: l10n.nutrition,
                        subtitle: l10n.nutritionSubtitle,
                        icon: Icons.restaurant,
                        color: AppColors.nutrition,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NutritionScreen(),
                          ),
                        ),
                      ),
                    ),
                    if (settingsRepo.cycleTrackingEnabled) ...[
                      const SizedBox(height: 20),
                      Expanded(
                        child: _HomeCard(
                          title: l10n.cycleTracking,
                          subtitle: l10n.cycleTrackingSubtitle,
                          icon: Icons.calendar_month,
                          color: AppColors.cycle,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CycleScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (settingsRepo.muscleRankEnabled) ...[
                      const SizedBox(height: 20),
                      Expanded(
                        child: _HomeCard(
                          title: 'Body Rank',
                          subtitle: 'Your per-muscle rank diagram',
                          icon: Icons.accessibility_new,
                          color: AppColors.bodyRank,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BodyRankScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
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
