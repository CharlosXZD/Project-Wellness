import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/sharing/share_codec.dart';
import '../core/sharing/share_dispatch.dart';
import '../features/training/day_templates_screen.dart';
import '../models/food_entry.dart';
import '../repositories/nutrition_repository.dart';
import '../repositories/training_repository.dart';

/// Paste-a-code dialog shared by the workout (single-day/split) and
/// nutrition (snack/meal combo) share features — it decodes the code and
/// branches on what it turns out to be.
Future<void> showImportCodeDialog(BuildContext context) async {
  final controller = TextEditingController();

  final code = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Import shared code'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Paste the code here',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Import'),
        ),
      ],
    ),
  );

  if (code == null || code.isEmpty || !context.mounted) return;

  DecodedShare decoded;
  try {
    decoded = decodeAny(code);
  } on ShareCodeException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
    return;
  }

  final repo = context.read<TrainingRepository>();

  switch (decoded) {
    case DecodedComboShare(:final combo):
      await context.read<NutritionRepository>().addCombo(combo);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${combo.name} added to your ${combo.defaultMealType == MealType.snack ? 'snacks' : 'meals'}',
            ),
          ),
        );
      }
      break;
    case DecodedTemplateShare(:final template):
      await repo.createTemplate(template);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DayTemplatesScreen(dayName: template.dayName),
          ),
        );
      }
      break;
    case DecodedSplitShare(:final bundle):
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import split?'),
          content: Text(
            "Import '${bundle.split.name}' with "
            '${bundle.templates.length} workout'
            '${bundle.templates.length == 1 ? '' : 's'}? '
            'Your current split will be replaced; existing workouts and '
            'logged sessions are kept.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await repo.importSplitBundle(bundle.split, bundle.templates);
      }
      break;
    case DecodedCustomExerciseShare(:final exercise):
      await repo.createCustomExercise(exercise);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${exercise.name} added to your personal exercises')),
        );
      }
    case DecodedLibraryShare(:final bundle):
      final addedExercises = await repo.mergeCustomExercises(bundle.exercises);
      final addedFoods = context.mounted
          ? await context
              .read<NutritionRepository>()
              .mergePersonalFoods(bundle.foods)
          : 0;
      if (context.mounted) {
        final skippedExercises = bundle.exercises.length - addedExercises;
        final skippedFoods = bundle.foods.length - addedFoods;
        final skipped = skippedExercises + skippedFoods;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added $addedExercises exercise${addedExercises == 1 ? '' : 's'}, '
              '$addedFoods food${addedFoods == 1 ? '' : 's'}'
              '${skipped > 0 ? ' — skipped $skipped already in your library' : ''}',
            ),
          ),
        );
      }
  }
}
