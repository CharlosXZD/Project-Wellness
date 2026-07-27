import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/units/units.dart';
import '../../models/exercise_def.dart';
import '../../models/workout_template.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/exercise_icon.dart';
import '../../widgets/numeric_input_dialog.dart';
import '../../widgets/numeric_stepper.dart';

class _BaselineDraft {
  final ExerciseDef def;
  int sets = 3;
  int reps = 10;
  double weightKg = 0;
  bool unilateral;

  _BaselineDraft({
    required this.def,
    required this.unilateral,
  });

  bool get canToggleUnilateral =>
      def.category == 'Biceps' || def.category == 'Triceps' || def.category == 'Forearms' || def.category == 'Legs';
}

/// Shown right after picking exercises for a new workout (before it's
/// saved) — lets the user set a starting sets/reps/weight baseline per
/// exercise (and, for arm/leg exercises, mark it unilateral) so the very
/// first real session already has something to compare against instead of
/// starting every set at 0 with no history. Arm/forearm/leg exercises can
/// be marked unilateral (see [_BaselineDraft.canToggleUnilateral]).
class TemplateBaselineScreen extends StatefulWidget {
  final String dayName;
  final String templateName;
  final List<ExerciseDef> exercises;

  const TemplateBaselineScreen({
    super.key,
    required this.dayName,
    required this.templateName,
    required this.exercises,
  });

  @override
  State<TemplateBaselineScreen> createState() => _TemplateBaselineScreenState();
}

class _TemplateBaselineScreenState extends State<TemplateBaselineScreen> {
  late final List<_BaselineDraft> _drafts = widget.exercises
      .map((def) => _BaselineDraft(def: def, unilateral: def.unilateral))
      .toList();
  bool _saving = false;

  void _reorderDrafts(int oldIndex, int newIndex) {
    setState(() {
      _drafts.insert(newIndex, _drafts.removeAt(oldIndex));
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final templateId = const Uuid().v4();
    final exercises = [
      for (var i = 0; i < _drafts.length; i++)
        TemplateExercise(
          id: const Uuid().v4(),
          templateId: templateId,
          exerciseName: _drafts[i].def.name,
          category: _drafts[i].def.category,
          orderIndex: i,
          targetSets: _drafts[i].sets,
          targetReps: _drafts[i].reps,
          targetWeightKg: _drafts[i].weightKg,
          unilateral: _drafts[i].unilateral,
        ),
    ];

    final template = WorkoutTemplate(
      id: templateId,
      dayName: widget.dayName,
      name: widget.templateName,
      createdAt: DateTime.now(),
      exercises: exercises,
    );

    await context.read<TrainingRepository>().createTemplate(template);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final unitSystem = context.watch<SettingsRepository>().unitSystem;

    return Scaffold(
      appBar: AppBar(title: const Text('Starting stats')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set a starting point for each exercise',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'This is what your next workout compares against — you can always adjust it live.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              buildDefaultDragHandles: false,
              onReorderItem: _reorderDrafts,
              itemCount: _drafts.length,
              itemBuilder: (context, index) {
                final draft = _drafts[index];
                return Padding(
                  key: ValueKey(draft.def.name),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _BaselineCard(draft: draft, index: index, unitSystem: unitSystem),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Save workout'),
        ),
      ),
    );
  }
}

class _BaselineCard extends StatefulWidget {
  final _BaselineDraft draft;
  final int index;
  final UnitSystem unitSystem;

  const _BaselineCard({required this.draft, required this.index, required this.unitSystem});

  @override
  State<_BaselineCard> createState() => _BaselineCardState();
}

class _BaselineCardState extends State<_BaselineCard> {
  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final unitSystem = widget.unitSystem;
    final unitLabel = Units.weightUnitLabel(unitSystem);
    final displayWeight =
        unitSystem == UnitSystem.metric ? draft.weightKg : Units.kgToLbs(draft.weightKg);
    final step = Units.weightStep(unitSystem);
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
                  index: widget.index,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(Icons.drag_indicator, color: scheme.onSurfaceVariant),
                  ),
                ),
                ExerciseIcon(exercise: draft.def, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(draft.def.name, style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 12),
            NumericStepper(
              label: 'sets',
              semanticName: 'sets',
              value: '${draft.sets}',
              onDecrement: () => setState(() => draft.sets = (draft.sets - 1).clamp(1, 10)),
              onIncrement: () => setState(() => draft.sets = (draft.sets + 1).clamp(1, 10)),
            ),
            const SizedBox(height: 10),
            // Same weight/reps pairing (2 across, not 3) as the active
            // workout screen's set rows, so this looks like the same
            // control instead of a squeezed-down variant of it.
            Row(
              children: [
                Expanded(
                  child: NumericStepper(
                    label: unitLabel,
                    semanticName: 'weight',
                    value: Units.formatNumber(displayWeight),
                    onDecrement: () => setState(
                      () => draft.weightKg = Units.roundStorage((draft.weightKg - step).clamp(0, 500)),
                    ),
                    onIncrement: () => setState(
                      () => draft.weightKg = Units.roundStorage((draft.weightKg + step).clamp(0, 500)),
                    ),
                    onTapValue: () async {
                      final typed = await showNumericInputDialog(
                        context,
                        title: 'Weight ($unitLabel)',
                        initialValue: displayWeight,
                      );
                      if (typed != null) {
                        final typedKg =
                            unitSystem == UnitSystem.metric ? typed : Units.lbsToKg(typed);
                        setState(() => draft.weightKg = Units.roundStorage(typedKg.clamp(0, 500)));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NumericStepper(
                    label: 'reps',
                    semanticName: 'reps',
                    value: '${draft.reps}',
                    onDecrement: () => setState(() => draft.reps = (draft.reps - 1).clamp(0, 100)),
                    onIncrement: () => setState(() => draft.reps = (draft.reps + 1).clamp(0, 100)),
                    onTapValue: () async {
                      final typed = await showNumericInputDialog(
                        context,
                        title: 'Reps',
                        initialValue: draft.reps.toDouble(),
                        allowDecimal: false,
                      );
                      if (typed != null) setState(() => draft.reps = typed.round().clamp(0, 100));
                    },
                  ),
                ),
              ],
            ),
            if (draft.canToggleUnilateral) ...[
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Unilateral'),
                subtitle: const Text('Trained one side at a time'),
                value: draft.unilateral,
                onChanged: (v) => setState(() => draft.unilateral = v),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
