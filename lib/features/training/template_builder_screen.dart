import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/exercise_library.dart';
import '../../models/custom_exercise.dart';
import '../../models/exercise_def.dart';
import '../../models/workout_template.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/create_exercise_card.dart';
import '../../widgets/exercise_icon.dart';
import '../../widgets/watch_form_video_button.dart';
import 'custom_exercise_editor_screen.dart';
import 'template_baseline_screen.dart';

const _personalCategory = 'Personal';

class TemplateBuilderScreen extends StatefulWidget {
  final String dayName;
  final WorkoutTemplate? existingTemplate;

  const TemplateBuilderScreen({
    super.key,
    required this.dayName,
    this.existingTemplate,
  });

  @override
  State<TemplateBuilderScreen> createState() => _TemplateBuilderScreenState();
}

class _TemplateBuilderScreenState extends State<TemplateBuilderScreen> {
  late final TextEditingController _nameController;
  final TextEditingController _searchController = TextEditingController();
  late String _selectedCategory;
  final List<ExerciseDef> _selected = [];
  bool _saving = false;

  bool get _isEditing => widget.existingTemplate != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTemplate;
    if (existing != null) {
      final repo = context.read<TrainingRepository>();
      _nameController = TextEditingController(text: existing.name);
      _selected.addAll(
        existing.exercises.map(
          (e) =>
              repo.exerciseDefByName(e.exerciseName) ??
              ExerciseDef(name: e.exerciseName, category: e.category),
        ),
      );
    } else {
      final existingCount = context
          .read<TrainingRepository>()
          .templatesForDay(widget.dayName)
          .length;
      _nameController = TextEditingController(
        text: '${widget.dayName} Day ${existingCount + 1}',
      );
    }
    _selectedCategory = 'All';
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _chipCategories {
    final hasCustom = context.watch<TrainingRepository>().customExercises.isNotEmpty;
    final suggested = suggestedCategoriesForDay(widget.dayName);
    final rest = exerciseCategories.where((c) => !suggested.contains(c));
    return ['All', if (hasCustom) _personalCategory, ...suggested, ...rest];
  }

  List<ExerciseDef> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final customDefs = context
        .watch<TrainingRepository>()
        .customExercises
        .map((c) => c.toExerciseDef());
    final all = [...exerciseLibrary, ...customDefs];
    if (_selectedCategory == _personalCategory) {
      return customDefs
          .where((e) => query.isEmpty || e.name.toLowerCase().contains(query))
          .toList();
    }
    return all.where((e) {
      final matchesCategory =
          _selectedCategory == 'All' || e.category == _selectedCategory;
      final matchesQuery = query.isEmpty || e.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _toggleExercise(ExerciseDef exercise) {
    setState(() {
      final existingIndex =
          _selected.indexWhere((e) => e.name == exercise.name);
      if (existingIndex >= 0) {
        _selected.removeAt(existingIndex);
      } else {
        _selected.add(exercise);
      }
    });
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
    setState(() {
      _selected.add(created.toExerciseDef());
      _searchController.clear();
    });
  }

  String get _templateName => _nameController.text.trim().isEmpty
      ? '${widget.dayName} workout'
      : _nameController.text.trim();

  /// Editing an existing template saves directly — there's already real
  /// session history to compare against, so there's no "baseline" to set.
  Future<void> _save() async {
    if (_selected.isEmpty || _saving) return;
    setState(() => _saving = true);

    final existing = widget.existingTemplate!;
    final exercises = [
      for (var i = 0; i < _selected.length; i++)
        TemplateExercise(
          id: const Uuid().v4(),
          templateId: existing.id,
          exerciseName: _selected[i].name,
          category: _selected[i].category,
          orderIndex: i,
        ),
    ];

    final template = WorkoutTemplate(
      id: existing.id,
      dayName: widget.dayName,
      name: _templateName,
      createdAt: existing.createdAt,
      exercises: exercises,
    );

    await context.read<TrainingRepository>().updateTemplate(template);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existingTemplate;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this workout?'),
        content: Text(
          'This removes "${existing.name}" entirely. Workouts you\'ve already logged with it are kept. This can\'t be undone.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<TrainingRepository>().deleteTemplate(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  /// A brand-new template goes through [TemplateBaselineScreen] first, to
  /// set a starting sets/reps/weight per exercise — that screen does the
  /// actual `createTemplate` call and pops `true` on success, at which
  /// point this screen pops too so both are gone from the stack.
  Future<void> _continue() async {
    if (_selected.isEmpty) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TemplateBaselineScreen(
          dayName: widget.dayName,
          templateName: _templateName,
          exercises: _selected,
        ),
      ),
    );
    if (saved == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final noMatches = filtered.isEmpty && _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit ${widget.existingTemplate!.name}' : 'New ${widget.dayName} workout'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: scheme.error),
              tooltip: 'Delete workout',
              onPressed: _delete,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Workout name'),
            ),
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_selected.length} exercise${_selected.length == 1 ? '' : 's'} added',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final exercise in _selected)
                    _SelectedExerciseChip(
                      key: ValueKey(exercise.name),
                      exercise: exercise,
                      onRemove: () => _toggleExercise(exercise),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                  onSelected: (_) => setState(() => _selectedCategory = category),
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
                            label: Text('Add "${_searchController.text.trim()}"'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return CreateExerciseCard(onTap: _createExercise);
                      }
                      final exercise = filtered[index - 1];
                      final isSelected =
                          _selected.any((e) => e.name == exercise.name);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: isSelected
                              ? scheme.primary.withValues(alpha: 0.14)
                              : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _toggleExercise(exercise),
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
                                    color: isSelected
                                        ? scheme.primary
                                        : scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      exercise.name,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                  WatchFormVideoButton(videoUrl: exercise.videoUrl),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.add_circle_outline,
                                    color: isSelected
                                        ? scheme.primary
                                        : scheme.onSurfaceVariant,
                                  ),
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: FilledButton(
          onPressed: _selected.isEmpty || _saving
              ? null
              : (_isEditing ? _save : _continue),
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Text(_isEditing ? 'Save changes' : 'Continue'),
        ),
      ),
    );
  }
}

/// Compact icon-only representation of an added exercise, so the "N
/// exercises added" area stays a few rows tall no matter how many are
/// picked, instead of pushing the search field down one full-width row per
/// exercise. Tap anywhere on the chip (or the badge) to remove it; the name
/// shows on long-press/hover via the tooltip.
class _SelectedExerciseChip extends StatelessWidget {
  final ExerciseDef exercise;
  final VoidCallback onRemove;

  const _SelectedExerciseChip({super.key, required this.exercise, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: exercise.name,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: scheme.primary.withValues(alpha: 0.14),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: ExerciseIcon(exercise: exercise, size: 22, color: scheme.primary),
                ),
              ),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Material(
                color: scheme.errorContainer,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(Icons.close, size: 12, color: scheme.onErrorContainer),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
