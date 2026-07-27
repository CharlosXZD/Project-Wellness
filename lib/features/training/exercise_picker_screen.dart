import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/exercise_library.dart';
import '../../models/custom_exercise.dart';
import '../../models/exercise_def.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/create_exercise_card.dart';
import '../../widgets/exercise_icon.dart';
import '../../widgets/watch_form_video_button.dart';
import 'custom_exercise_editor_screen.dart';

const _personalCategory = 'Personal';

/// Single-selection exercise picker used to add one exercise to an
/// already-in-progress workout — pops with the picked [ExerciseDef] as soon
/// as a row is tapped. Deliberately a separate, lightweight screen rather
/// than a refactor of [TemplateBuilderScreen]'s multi-select picker, so that
/// already-shipped flow isn't put at risk for this.
class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _chipCategories {
    final hasCustom =
        context.watch<TrainingRepository>().customExercises.isNotEmpty;
    return ['All', if (hasCustom) _personalCategory, ...exerciseCategories];
  }

  List<ExerciseDef> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final customDefs = context
        .watch<TrainingRepository>()
        .customExercises
        .map((c) => c.toExerciseDef());
    if (_selectedCategory == _personalCategory) {
      return customDefs
          .where((e) => query.isEmpty || e.name.toLowerCase().contains(query))
          .toList();
    }
    final all = [...exerciseLibrary, ...customDefs];
    return all.where((e) {
      final matchesCategory =
          _selectedCategory == 'All' || e.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty || e.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> _addCustomExercise() async {
    final name = _searchController.text.trim();
    if (name.isEmpty) return;
    await _createExercise(initialName: name);
  }

  Future<void> _createExercise({String? initialName}) async {
    final created = await Navigator.of(context).push<CustomExercise>(
      MaterialPageRoute(
        builder: (_) => CustomExerciseEditorScreen(initialName: initialName),
      ),
    );
    if (created == null || !mounted) return;
    Navigator.of(context).pop(created.toExerciseDef());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final noMatches =
        filtered.isEmpty && _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Add exercise')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search exercises',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _searchController.clear,
                          tooltip: 'Clear search',
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _chipCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _chipCategories[index];
                  final isSelected = category == _selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: noMatches
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'No exercise called "${_searchController.text.trim()}"',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _addCustomExercise,
                              icon: const Icon(Icons.add),
                              label: Text(
                                  'Add "${_searchController.text.trim()}"'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: filtered.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return CreateExerciseCard(onTap: _createExercise);
                        }
                        final exercise = filtered[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.of(context).pop(exercise),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    ExerciseIcon(
                                      exercise: exercise,
                                      size: 26,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        exercise.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    ),
                                    WatchFormVideoButton(
                                        videoUrl: exercise.videoUrl),
                                    Icon(Icons.add_circle_outline,
                                        color: scheme.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
