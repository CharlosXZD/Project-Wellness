import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/training/exercise_series.dart';
import '../../core/training/medal_unlock.dart';
import '../../core/units/units.dart';
import '../../models/workout_session.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/exercise_progress_chart.dart';
import 'session_exercise_editor_screen.dart';

/// Shown when tapping a logged workout session — lets the user fix the
/// name/date, edit or remove an individual exercise's sets, or delete the
/// whole session.
class SessionDetailScreen extends StatefulWidget {
  final WorkoutSession session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late final _nameController = TextEditingController(text: widget.session.name);
  late DateTime _date = widget.session.date;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    await context.read<TrainingRepository>().updateSessionInfo(
          widget.session.id,
          name: _nameController.text.trim(),
          date: _date,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this workout?'),
        content: Text('This removes "${widget.session.name}" from your history. This can\'t be undone.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<TrainingRepository>().deleteSession(widget.session.id);
    if (!mounted) return;
    await reconcileMedalsAfterDeletion(context);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unitSystem = context.watch<SettingsRepository>().unitSystem;
    // Re-read live from the repository (rather than the original
    // `widget.session` snapshot) so editing/removing an exercise below is
    // reflected immediately without leaving/re-entering this screen.
    final session = context.watch<TrainingRepository>().sessions.firstWhere(
          (s) => s.id == widget.session.id,
          orElse: () => widget.session,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout details'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: scheme.error),
            tooltip: 'Delete',
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Workout name'),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date'),
              child: Text(DateFormat.yMMMd().format(_date)),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              session.dayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          Text('Exercises', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final exercise in session.exercises)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: exercise.sets.isEmpty
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SessionExerciseEditorScreen(exercise: exercise),
                                ),
                              ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exercise.exerciseName, style: Theme.of(context).textTheme.bodyLarge),
                                  const SizedBox(height: 4),
                                  Text(
                                    exercise.durationSeconds != null
                                        ? '${(exercise.durationSeconds! / 60).round()} min'
                                        : exercise.sets
                                            .map((s) =>
                                                '${Units.formatWeight(s.weightKg, unitSystem, decimals: 0)} × ${s.reps}')
                                            .join(' · '),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (exercise.sets.isNotEmpty)
                              Icon(Icons.edit_outlined, size: 18, color: scheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                    if (exercise.sets.isNotEmpty)
                      Builder(builder: (context) {
                        final series = buildExerciseWeightSeries(
                          exercise.exerciseName,
                          context.watch<TrainingRepository>().sessions,
                        );
                        if (series.length < 2) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: ExerciseProgressChart(points: series, unitSystem: unitSystem),
                        );
                      }),
                  ],
                ),
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
              : const Text('Save changes'),
        ),
      ),
    );
  }
}
