import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/active_workout_route_observer.dart';
import '../../core/training/duration_format.dart';
import '../../core/units/units.dart';
import '../../models/exercise_def.dart';
import '../../models/workout_session.dart';
import '../../repositories/active_workout_repository.dart';
import '../../repositories/medals_repository.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/numeric_input_dialog.dart';
import '../../widgets/numeric_stepper.dart';
import '../../widgets/watch_form_video_button.dart';
import 'exercise_picker_screen.dart';
import 'workout_summary_screen.dart';

/// A view over the in-progress workout held by [ActiveWorkoutRepository] —
/// it owns no workout state itself (that's what lets the persistent
/// `ActiveWorkoutBar` and this screen show the same thing), only the
/// `RouteAware` bookkeeping that tells the repository whether this screen
/// is the visible top route right now.
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> with RouteAware {
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) activeWorkoutRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    activeWorkoutRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() => context.read<ActiveWorkoutRepository>().setScreenVisible(true);

  @override
  void didPopNext() => context.read<ActiveWorkoutRepository>().setScreenVisible(true);

  @override
  void didPushNext() => context.read<ActiveWorkoutRepository>().setScreenVisible(false);

  @override
  void didPop() => context.read<ActiveWorkoutRepository>().setScreenVisible(false);

  Future<void> _addExercise(ActiveWorkoutRepository activeRepo) async {
    final picked = await Navigator.of(context).push<ExerciseDef>(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (picked == null || !mounted) return;

    final saveAsTemplate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add exercise'),
        content: Text(
          'Add "${picked.name}" just to today\'s workout, or also save it into '
          'a new version of this template for next time?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Just for today'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Also save as new template'),
          ),
        ],
      ),
    );
    if (saveAsTemplate == null || !mounted) return;

    await activeRepo.addExercise(
      context.read<TrainingRepository>(),
      picked,
      saveAsTemplate: saveAsTemplate,
    );
  }

  Future<void> _finish(ActiveWorkoutRepository activeRepo) async {
    if (_saving) return;
    setState(() => _saving = true);

    final (session, summary, newlyUnlocked) = await activeRepo.finish(
      trainingRepo: context.read<TrainingRepository>(),
      medalsRepo: context.read<MedalsRepository>(),
      nutritionRepo: context.read<NutritionRepository>(),
    );
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          session: session,
          summary: summary,
          newlyUnlockedMedals: newlyUnlocked,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeRepo = context.watch<ActiveWorkoutRepository>();
    final template = activeRepo.template;
    final drafts = activeRepo.drafts;
    final unitSystem = context.watch<SettingsRepository>().unitSystem;

    if (template == null) {
      // Reached with nothing active (e.g. a stale deep link) — nothing to
      // show, just back out.
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No active workout')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(template.name),
        actions: [
          IconButton(
            onPressed: activeRepo.isPaused ? activeRepo.resume : activeRepo.pause,
            icon: Icon(activeRepo.isPaused ? Icons.play_arrow : Icons.pause),
            tooltip: activeRepo.isPaused ? 'Resume' : 'Pause',
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Icon(activeRepo.isPaused ? Icons.pause_circle_outline : Icons.timer_outlined, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    formatElapsedDuration(activeRepo.elapsed),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () => _addExercise(activeRepo),
            child: const Text('Add exercise'),
          ),
        ],
      ),
      body: drafts == null
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              buildDefaultDragHandles: false,
              onReorderItem: activeRepo.reorderExercise,
              itemCount: drafts.length,
              itemBuilder: (context, index) {
                final draft = drafts[index];
                return Padding(
                  key: ValueKey(draft.template.id),
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _ExerciseCard(
                    draft: draft,
                    index: index,
                    unitSystem: unitSystem,
                    onAdjustWeight: activeRepo.adjustWeight,
                    onAdjustReps: activeRepo.adjustReps,
                    onAddSet: () => activeRepo.addSet(draft),
                    onRemoveSet: (set) => activeRepo.removeSet(draft, set),
                    onAdjustDuration: (delta) => activeRepo.adjustDuration(draft, delta),
                    onAdjustCalories: (delta) => activeRepo.adjustCalories(draft, delta),
                    onAdjustDistance: (delta) => activeRepo.adjustDistance(draft, delta),
                    onRemoveExercise: () => activeRepo.removeExercise(draft),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: FilledButton(
          onPressed: drafts == null || drafts.isEmpty || _saving ? null : () => _finish(activeRepo),
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Finish workout'),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ActiveWorkoutExerciseDraft draft;
  final int index;
  final UnitSystem unitSystem;
  final void Function(ActiveWorkoutSetDraft set, double delta) onAdjustWeight;
  final void Function(ActiveWorkoutSetDraft set, int delta) onAdjustReps;
  final VoidCallback onAddSet;
  final void Function(ActiveWorkoutSetDraft set) onRemoveSet;
  final void Function(int deltaMinutes) onAdjustDuration;
  final void Function(int delta) onAdjustCalories;
  final void Function(double delta) onAdjustDistance;
  final VoidCallback onRemoveExercise;

  const _ExerciseCard({
    required this.draft,
    required this.index,
    required this.unitSystem,
    required this.onAdjustWeight,
    required this.onAdjustReps,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onAdjustDuration,
    required this.onAdjustCalories,
    required this.onAdjustDistance,
    required this.onRemoveExercise,
  });

  @override
  Widget build(BuildContext context) {
    final isBodyweight = draft.isBodyweight;
    final videoUrl = draft.videoUrl;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(Icons.drag_indicator, color: scheme.onSurfaceVariant),
                  ),
                ),
                Expanded(
                  child: Text(
                    draft.template.exerciseName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (!draft.isDurationBased) WatchFormVideoButton(videoUrl: videoUrl),
                IconButton(
                  onPressed: onRemoveExercise,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove exercise',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (draft.isDurationBased) ...[
              NumericStepper(
                label: 'min',
                semanticName: 'duration',
                value: '${draft.durationMinutes}',
                onDecrement: () => onAdjustDuration(-1),
                onIncrement: () => onAdjustDuration(1),
                onTapValue: () async {
                  final typed = await showNumericInputDialog(
                    context,
                    title: 'Duration (min)',
                    initialValue: draft.durationMinutes.toDouble(),
                    allowDecimal: false,
                  );
                  if (typed != null) {
                    onAdjustDuration(typed.round() - draft.durationMinutes);
                  }
                },
              ),
              if (draft.isCardio) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: NumericStepper(
                        label: 'kcal',
                        semanticName: 'calories burned',
                        value: '${draft.caloriesBurned}',
                        onDecrement: () => onAdjustCalories(-10),
                        onIncrement: () => onAdjustCalories(10),
                        onTapValue: () async {
                          final typed = await showNumericInputDialog(
                            context,
                            title: 'Calories burned',
                            initialValue: draft.caloriesBurned.toDouble(),
                            allowDecimal: false,
                          );
                          if (typed != null) {
                            onAdjustCalories(typed.round() - draft.caloriesBurned);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: NumericStepper(
                        label: Units.distanceUnitLabel(unitSystem),
                        semanticName: 'distance',
                        value: Units.formatNumber(
                          unitSystem == UnitSystem.metric
                              ? draft.distanceKm
                              : Units.kmToMiles(draft.distanceKm),
                        ),
                        onDecrement: () => onAdjustDistance(
                          -(unitSystem == UnitSystem.metric ? 0.5 : Units.milesToKm(0.5)),
                        ),
                        onIncrement: () => onAdjustDistance(
                          unitSystem == UnitSystem.metric ? 0.5 : Units.milesToKm(0.5),
                        ),
                        onTapValue: () async {
                          final displayed = unitSystem == UnitSystem.metric
                              ? draft.distanceKm
                              : Units.kmToMiles(draft.distanceKm);
                          final typed = await showNumericInputDialog(
                            context,
                            title: 'Distance (${Units.distanceUnitLabel(unitSystem)})',
                            initialValue: displayed,
                          );
                          if (typed != null) {
                            final typedKm = unitSystem == UnitSystem.metric
                                ? typed
                                : Units.milesToKm(typed);
                            onAdjustDistance(typedKm - draft.distanceKm);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              if (videoUrl != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: WatchFormVideoButton(
                    videoUrl: videoUrl,
                    label: 'Watch & follow along',
                  ),
                ),
              ],
            ] else ...[
              for (var i = 0; i < draft.sets.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SetRow(
                    index: draft.isUnilateral ? (i ~/ 2) + 1 : i + 1,
                    set: draft.sets[i],
                    isBodyweight: isBodyweight,
                    unitSystem: unitSystem,
                    onAdjustWeight: (delta) => onAdjustWeight(draft.sets[i], delta),
                    onAdjustReps: (delta) => onAdjustReps(draft.sets[i], delta),
                    onRemove: draft.sets.length > 1
                        ? () => onRemoveSet(draft.sets[i])
                        : null,
                  ),
                ),
              TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add),
                label: const Text('Add set'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int index;
  final ActiveWorkoutSetDraft set;
  final bool isBodyweight;
  final UnitSystem unitSystem;
  final void Function(double delta) onAdjustWeight;
  final void Function(int delta) onAdjustReps;
  final VoidCallback? onRemove;

  const _SetRow({
    required this.index,
    required this.set,
    required this.isBodyweight,
    required this.unitSystem,
    required this.onAdjustWeight,
    required this.onAdjustReps,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unitLabel = Units.weightUnitLabel(unitSystem);
    final displayWeight = unitSystem == UnitSystem.metric
        ? set.weightKg
        : Units.kgToLbs(set.weightKg);
    final step = Units.weightStep(unitSystem);

    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(
            set.side != null ? '$index${set.side!.label}' : '$index',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: NumericStepper(
            label: isBodyweight ? '+$unitLabel' : unitLabel,
            semanticName: 'weight',
            value: Units.formatNumber(displayWeight),
            onDecrement: () => onAdjustWeight(-step),
            onIncrement: () => onAdjustWeight(step),
            onTapValue: () async {
              final typed = await showNumericInputDialog(
                context,
                title: 'Weight ($unitLabel)',
                initialValue: displayWeight,
              );
              if (typed != null) {
                final typedKg =
                    unitSystem == UnitSystem.metric ? typed : Units.lbsToKg(typed);
                onAdjustWeight(typedKg - set.weightKg);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: NumericStepper(
            label: 'reps',
            semanticName: 'reps',
            value: '${set.reps}',
            onDecrement: () => onAdjustReps(-1),
            onIncrement: () => onAdjustReps(1),
            onTapValue: () async {
              final typed = await showNumericInputDialog(
                context,
                title: 'Reps',
                initialValue: set.reps.toDouble(),
                allowDecimal: false,
              );
              if (typed != null) {
                onAdjustReps(typed.round() - set.reps);
              }
            },
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.close, size: 18),
          visualDensity: VisualDensity.compact,
          tooltip: 'Remove set',
        ),
      ],
    );
  }
}
