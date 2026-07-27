import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/training/medal_unlock.dart';
import '../../core/units/units.dart';
import '../../models/workout_session.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/numeric_input_dialog.dart';
import '../../widgets/numeric_stepper.dart';

class _MutableSet {
  double weightKg;
  int reps;
  final SetSide? side;

  _MutableSet({required this.weightKg, required this.reps, this.side});
}

/// Lets the user fix a mistake in an already-logged exercise (wrong weight,
/// wrong reps, forgot to remove a set) or remove the exercise from the
/// session entirely — reached by tapping an exercise on
/// `session_detail_screen.dart`.
class SessionExerciseEditorScreen extends StatefulWidget {
  final SessionExercise exercise;

  const SessionExerciseEditorScreen({super.key, required this.exercise});

  @override
  State<SessionExerciseEditorScreen> createState() => _SessionExerciseEditorScreenState();
}

class _SessionExerciseEditorScreenState extends State<SessionExerciseEditorScreen> {
  late final List<_MutableSet> _sets = widget.exercise.sets
      .map((s) => _MutableSet(weightKg: s.weightKg, reps: s.reps, side: s.side))
      .toList();
  bool get _isUnilateral => widget.exercise.sets.any((s) => s.side != null);
  bool _saving = false;

  void _addSet() {
    setState(() {
      if (_isUnilateral) {
        final lastLeft = _sets.lastWhere(
          (s) => s.side == SetSide.left,
          orElse: () => _MutableSet(weightKg: 0, reps: 10),
        );
        final lastRight = _sets.lastWhere(
          (s) => s.side == SetSide.right,
          orElse: () => _MutableSet(weightKg: 0, reps: 10),
        );
        _sets.add(_MutableSet(weightKg: lastLeft.weightKg, reps: lastLeft.reps, side: SetSide.left));
        _sets.add(_MutableSet(weightKg: lastRight.weightKg, reps: lastRight.reps, side: SetSide.right));
        return;
      }
      final last = _sets.isNotEmpty ? _sets.last : null;
      _sets.add(_MutableSet(weightKg: last?.weightKg ?? 0, reps: last?.reps ?? 10));
    });
  }

  void _removeSet(_MutableSet set) {
    if (_sets.length <= 1) return;
    setState(() => _sets.remove(set));
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final newSets = [
      for (var i = 0; i < _sets.length; i++)
        SessionSet(
          id: const Uuid().v4(),
          sessionExerciseId: widget.exercise.id,
          setIndex: _isUnilateral ? i ~/ 2 : i,
          weightKg: _sets[i].weightKg,
          reps: _sets[i].reps,
          side: _sets[i].side,
        ),
    ];

    await context.read<TrainingRepository>().updateSessionExercise(widget.exercise, newSets);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this exercise?'),
        content: Text(
          'This removes "${widget.exercise.exerciseName}" from this logged workout. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<TrainingRepository>().deleteSessionExercise(widget.exercise.id);
    if (!mounted) return;
    await reconcileMedalsAfterDeletion(context);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unitSystem = context.watch<SettingsRepository>().unitSystem;
    final unitLabel = Units.weightUnitLabel(unitSystem);
    final step = Units.weightStep(unitSystem);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.exerciseName),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: scheme.error),
            tooltip: 'Remove exercise',
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          for (var i = 0; i < _sets.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      _sets[i].side != null
                          ? '${_isUnilateral ? (i ~/ 2) + 1 : i + 1}${_sets[i].side!.label}'
                          : '${i + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  Expanded(
                    child: NumericStepper(
                      label: unitLabel,
                      semanticName: 'weight',
                      value: Units.formatNumber(
                        unitSystem == UnitSystem.metric
                            ? _sets[i].weightKg
                            : Units.kgToLbs(_sets[i].weightKg),
                      ),
                      onDecrement: () => setState(
                        () => _sets[i].weightKg =
                            Units.roundStorage((_sets[i].weightKg - step).clamp(0, 500)),
                      ),
                      onIncrement: () => setState(
                        () => _sets[i].weightKg =
                            Units.roundStorage((_sets[i].weightKg + step).clamp(0, 500)),
                      ),
                      onTapValue: () async {
                        final display = unitSystem == UnitSystem.metric
                            ? _sets[i].weightKg
                            : Units.kgToLbs(_sets[i].weightKg);
                        final typed = await showNumericInputDialog(
                          context,
                          title: 'Weight ($unitLabel)',
                          initialValue: display,
                        );
                        if (typed != null) {
                          final typedKg =
                              unitSystem == UnitSystem.metric ? typed : Units.lbsToKg(typed);
                          setState(() => _sets[i].weightKg = Units.roundStorage(typedKg.clamp(0, 500)));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NumericStepper(
                      label: 'reps',
                      semanticName: 'reps',
                      value: '${_sets[i].reps}',
                      onDecrement: () =>
                          setState(() => _sets[i].reps = (_sets[i].reps - 1).clamp(0, 100)),
                      onIncrement: () =>
                          setState(() => _sets[i].reps = (_sets[i].reps + 1).clamp(0, 100)),
                      onTapValue: () async {
                        final typed = await showNumericInputDialog(
                          context,
                          title: 'Reps',
                          initialValue: _sets[i].reps.toDouble(),
                          allowDecimal: false,
                        );
                        if (typed != null) {
                          setState(() => _sets[i].reps = typed.round().clamp(0, 100));
                        }
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: _sets.length > 1 ? () => _removeSet(_sets[i]) : null,
                    icon: const Icon(Icons.close, size: 18),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remove set',
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: _addSet,
            icon: const Icon(Icons.add),
            label: const Text('Add set'),
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
              : const Text('Save changes'),
        ),
      ),
    );
  }
}
