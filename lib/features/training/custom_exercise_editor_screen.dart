import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/exercise_library.dart';
import '../../models/custom_exercise.dart';
import '../../models/exercise_def.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/exercise_icon.dart';

/// Create or edit a personal exercise. Icon and form-video are expressed
/// through the same equipment/movement/videoUrl vocabulary every built-in
/// exercise uses (see docs/ICON_REGISTRY.md) rather than an uploaded photo
/// or video file — no new packages, and it renders identically everywhere
/// an [ExerciseDef] is already handled.
class CustomExerciseEditorScreen extends StatefulWidget {
  final CustomExercise? existing;
  final String? initialName;

  const CustomExerciseEditorScreen(
      {super.key, this.existing, this.initialName});

  @override
  State<CustomExerciseEditorScreen> createState() =>
      _CustomExerciseEditorScreenState();
}

class _CustomExerciseEditorScreenState
    extends State<CustomExerciseEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _videoUrlController;
  late String _category;
  late Equipment _equipment;
  MovementBadge? _movement;
  late bool _unilateral;
  late ExerciseTrackingType _trackingType;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController =
        TextEditingController(text: existing?.name ?? widget.initialName ?? '');
    _videoUrlController = TextEditingController(text: existing?.videoUrl ?? '');
    _category = existing?.category ?? exerciseCategories.first;
    _equipment = existing?.equipment ?? Equipment.other;
    _movement = existing?.movement;
    _unilateral = existing?.unilateral ?? false;
    _trackingType = existing?.trackingType ?? ExerciseTrackingType.standard;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  ExerciseDef get _previewDef => ExerciseDef(
        name: _nameController.text.trim().isEmpty
            ? 'Preview'
            : _nameController.text.trim(),
        category: _category,
        equipment: _equipment,
        movement: _movement,
        unilateral: _unilateral,
        trackingType: _trackingType,
      );

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;

    final videoUrl = _videoUrlController.text.trim();
    if (videoUrl.isNotEmpty && Uri.tryParse(videoUrl)?.hasScheme != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That video link doesn\'t look valid.')),
      );
      return;
    }

    setState(() => _saving = true);

    final existing = widget.existing;
    final exercise = CustomExercise(
      id: existing?.id ?? const Uuid().v4(),
      name: name,
      category: _category,
      equipment: _equipment,
      movement: _movement,
      unilateral: _unilateral,
      videoUrl: videoUrl.isEmpty ? null : videoUrl,
      trackingType: _trackingType,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    final repo = context.read<TrainingRepository>();
    if (existing != null) {
      await repo.updateCustomExercise(exercise);
    } else {
      await repo.createCustomExercise(exercise);
    }
    if (mounted) Navigator.of(context).pop(exercise);
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this exercise?'),
        content: Text(
            'This removes "${existing.name}" from your personal exercises. This can\'t be undone.'),
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

    await context.read<TrainingRepository>().deleteCustomExercise(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isEditing ? 'Edit personal exercise' : 'New personal exercise'),
        actions: [
          if (_isEditing)
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
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child:
                  Center(child: ExerciseIcon(exercise: _previewDef, size: 36)),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Exercise name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text('Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: exerciseCategories
                .map(
                  (c) => ChoiceChip(
                    label: Text(c),
                    selected: c == _category,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Text('Equipment (sets the icon)',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Equipment.values
                .map(
                  (e) => ChoiceChip(
                    label: Text(_equipmentLabel(e)),
                    selected: e == _equipment,
                    onSelected: (_) => setState(() => _equipment = e),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Text('Movement badge (optional)',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('None'),
                selected: _movement == null,
                onSelected: (_) => setState(() => _movement = null),
              ),
              ...MovementBadge.values.map(
                (m) => ChoiceChip(
                  label: Text(_movementLabel(m)),
                  selected: m == _movement,
                  onSelected: (_) => setState(() => _movement = m),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('How it\'s logged',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            'Timed exercises log a duration instead of sets; distance-based ones also '
            'log calories burned and distance.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExerciseTrackingType.values
                .map(
                  (t) => ChoiceChip(
                    label: Text(_trackingTypeLabel(t)),
                    selected: t == _trackingType,
                    onSelected: (_) => setState(() => _trackingType = t),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Unilateral'),
            subtitle: const Text(
                'Trained one side at a time — logs a left and a right set'),
            value: _unilateral,
            onChanged: (v) => setState(() => _unilateral = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _videoUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Form video link (optional)',
              hintText: 'https://youtube.com/...',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: FilledButton(
          onPressed:
              _nameController.text.trim().isEmpty || _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Text(_isEditing ? 'Save changes' : 'Save exercise'),
        ),
      ),
    );
  }
}

String _trackingTypeLabel(ExerciseTrackingType t) {
  switch (t) {
    case ExerciseTrackingType.standard:
      return 'Sets & reps';
    case ExerciseTrackingType.timed:
      return 'Timed';
    case ExerciseTrackingType.distance:
      return 'Distance';
  }
}

String _equipmentLabel(Equipment e) {
  switch (e) {
    case Equipment.barbell:
      return 'Barbell';
    case Equipment.dumbbell:
      return 'Dumbbell';
    case Equipment.kettlebell:
      return 'Kettlebell';
    case Equipment.cableMachine:
      return 'Cable / Machine';
    case Equipment.bodyweight:
      return 'Bodyweight';
    case Equipment.band:
      return 'Band';
    case Equipment.bench:
      return 'Bench';
    case Equipment.other:
      return 'Other';
  }
}

String _movementLabel(MovementBadge m) {
  switch (m) {
    case MovementBadge.press:
      return 'Press';
    case MovementBadge.curl:
      return 'Curl';
    case MovementBadge.pull:
      return 'Pull';
    case MovementBadge.pulldown:
      return 'Pulldown';
    case MovementBadge.extension:
      return 'Extension';
    case MovementBadge.raise:
      return 'Raise';
    case MovementBadge.squat:
      return 'Squat';
    case MovementBadge.hipThrust:
      return 'Hip Thrust';
    case MovementBadge.twist:
      return 'Twist';
    case MovementBadge.carry:
      return 'Carry';
    case MovementBadge.jump:
      return 'Jump';
    case MovementBadge.hold:
      return 'Hold';
    case MovementBadge.swing:
      return 'Swing';
    case MovementBadge.rotationalPress:
      return 'Rotational Press';
    case MovementBadge.roll:
      return 'Roll';
  }
}
