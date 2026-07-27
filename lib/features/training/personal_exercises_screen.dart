import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/sharing/library_share.dart';
import '../../core/sharing/workout_share.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/action_card.dart';
import '../../widgets/import_code_dialog.dart';
import '../../widgets/rect_button.dart';
import '../../widgets/share_code_sheet.dart';
import 'custom_exercise_editor_screen.dart';

/// Lists this user's personal (custom) exercises — create, edit, share, or
/// delete. Reached from Settings; the "Personal" chip in the exercise
/// pickers surfaces the same list when building a workout.
class PersonalExercisesScreen extends StatelessWidget {
  const PersonalExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exercises = context.watch<TrainingRepository>().customExercises;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Exercises')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Your personal exercises',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Create your own, with an icon, movement badge, and form video link.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            for (final exercise in exercises)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActionCard(
                  icon: Icons.fitness_center,
                  title: exercise.name,
                  subtitle: exercise.category,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CustomExerciseEditorScreen(existing: exercise),
                    ),
                  ),
                  onShare: () => showShareCodeSheet(
                    context,
                    title: 'Share ${exercise.name}',
                    code: encodeCustomExercise(exercise),
                    shareSubject: 'My ${exercise.name} exercise',
                  ),
                ),
              ),
            RectButton(
              icon: Icons.add_circle_outline,
              title: 'New personal exercise',
              outlined: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const CustomExerciseEditorScreen()),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: const Text('Export my library'),
                    onPressed: () => showShareCodeSheet(
                      context,
                      title: 'Export my library',
                      code: encodeLibraryBundle(
                        exercises: exercises,
                        foods:
                            context.read<NutritionRepository>().personalFoods,
                      ),
                      shareSubject: 'My personal exercises & foods',
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Import shared library'),
                    onPressed: () => showImportCodeDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
