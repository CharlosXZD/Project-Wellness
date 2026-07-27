import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/sharing/workout_share.dart';
import '../../models/workout_template.dart';
import '../../repositories/active_workout_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/action_card.dart';
import '../../widgets/rect_button.dart';
import '../../widgets/share_code_sheet.dart';
import 'active_workout_screen.dart';
import 'template_builder_screen.dart';
import 'workout_countdown_screen.dart';

class DayTemplatesScreen extends StatelessWidget {
  final String dayName;

  const DayTemplatesScreen({super.key, required this.dayName});

  @override
  Widget build(BuildContext context) {
    final templates = context
        .watch<TrainingRepository>()
        .templatesForDay(dayName);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(dayName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Your $dayName workouts',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Pick one to log, or create a new one.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            for (final template in templates)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActionCard(
                  icon: Icons.fitness_center,
                  title: template.name,
                  subtitle:
                      '${template.exercises.length} exercise${template.exercises.length == 1 ? '' : 's'}',
                  onTap: () => _startWorkout(context, template),
                  onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TemplateBuilderScreen(
                        dayName: dayName,
                        existingTemplate: template,
                      ),
                    ),
                  ),
                  onShare: () => _shareTemplate(context, template),
                ),
              ),
            RectButton(
              icon: Icons.add_circle_outline,
              title: 'Create new $dayName workout',
              outlined: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TemplateBuilderScreen(dayName: dayName),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Starts [template] — resumes it directly if it's already the active
  /// workout, confirms before discarding a *different* in-progress workout,
  /// or just runs the usual countdown if nothing's active.
  Future<void> _startWorkout(BuildContext context, WorkoutTemplate template) async {
    final activeRepo = context.read<ActiveWorkoutRepository>();

    if (activeRepo.hasActiveWorkout) {
      if (activeRepo.template?.id == template.id) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
        );
        return;
      }

      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard in-progress workout?'),
          content: Text(
            'You have "${activeRepo.template!.name}" in progress. '
            'Starting "${template.name}" will discard it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard & start'),
            ),
          ],
        ),
      );
      if (discard != true || !context.mounted) return;
      activeRepo.discard();
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkoutCountdownScreen(template: template)),
    );
  }

  void _shareTemplate(BuildContext context, WorkoutTemplate template) {
    showShareCodeSheet(
      context,
      title: 'Share ${template.name}',
      code: encodeTemplate(template),
      shareSubject: 'My ${template.name} workout',
    );
  }
}
