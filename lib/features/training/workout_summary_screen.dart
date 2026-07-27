import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/training/exercise_series.dart';
import '../../core/training/workout_summary.dart';
import '../../core/units/units.dart';
import '../../models/workout_session.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/exercise_progress_chart.dart';

/// Shown right after "Finish workout" — total time plus a per-exercise
/// comparison against history, and (once medals exist) a banner for
/// anything newly unlocked. `newlyUnlockedMedals` is a typed seam for that:
/// left empty until the medals system exists, but the screen already knows
/// how to render it so wiring medals in later doesn't reshape this screen.
class WorkoutSummaryScreen extends StatelessWidget {
  final WorkoutSession session;
  final List<ExerciseProgress> summary;
  final List<String> newlyUnlockedMedals;

  const WorkoutSummaryScreen({
    super.key,
    required this.session,
    required this.summary,
    this.newlyUnlockedMedals = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unitSystem = context.watch<SettingsRepository>().unitSystem;
    final allSessions = context.watch<TrainingRepository>().sessions;
    final minutes = session.durationMinutes ?? 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Workout complete'), automaticallyImplyLeading: false),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 56, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text(session.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    minutes >= 60
                        ? '${minutes ~/ 60}h ${minutes % 60}m'
                        : '$minutes min',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (newlyUnlockedMedals.isNotEmpty) ...[
              const SizedBox(height: 24),
              Material(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TrophyPop(color: Colors.amber.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'New medal${newlyUnlockedMedals.length == 1 ? '' : 's'} unlocked!',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final medal in newlyUnlockedMedals)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            medal,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text('How it went', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final progress in summary)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProgressCard(
                    progress: progress,
                    unitSystem: unitSystem,
                    weightSeries: buildExerciseWeightSeries(progress.exerciseName, allSessions),
                  ),
                ),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: () => Navigator.of(context).popUntil(
              (route) => route.settings.name == 'training' || route.isFirst,
            ),
            child: const Text('Done'),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ExerciseProgress progress;
  final UnitSystem unitSystem;
  final List<ExerciseWeightPoint> weightSeries;

  const _ProgressCard({
    required this.progress,
    required this.unitSystem,
    required this.weightSeries,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lines = <String>[
      '${progress.repsThisSession} reps'
          '${progress.repsDelta != null ? _signed(progress.repsDelta!) : ''}',
      'Top set ${Units.formatWeight(progress.topWeightKgThisSession, unitSystem, decimals: 0)}'
          '${progress.weightDeltaVs3MonthsAgo != null ? ' (${_signedWeight(progress.weightDeltaVs3MonthsAgo!, unitSystem)} vs 3 months ago)' : ''}',
    ];

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          progress.exerciseName,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      if (progress.isNewPr)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PR!',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (final line in lines)
                    Text(
                      line,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  if (weightSeries.length >= 2) ...[
                    const SizedBox(height: 12),
                    ExerciseProgressChart(points: weightSeries, unitSystem: unitSystem),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _signed(int value) => value == 0 ? '' : (value > 0 ? ' (+$value)' : ' ($value)');

  String _signedWeight(double deltaKg, UnitSystem unitSystem) {
    final delta = unitSystem == UnitSystem.metric ? deltaKg : Units.kgToLbs(deltaKg);
    final sign = delta >= 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(1)} ${Units.weightUnitLabel(unitSystem)}';
  }
}

/// Small scale+rotate "pop" entrance for the trophy icon on a medal-unlock
/// banner — plain `TweenAnimationBuilder`, no new package, runs once on
/// first build.
class _TrophyPop extends StatelessWidget {
  final Color color;

  const _TrophyPop({required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Transform.rotate(angle: (1 - value) * 0.6, child: child),
        );
      },
      child: Icon(Icons.emoji_events, color: color, size: 28),
    );
  }
}
