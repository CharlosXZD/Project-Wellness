import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/workout_split.dart';
import '../../repositories/training_repository.dart';

class _DayDraft {
  final controller = TextEditingController();

  void dispose() => controller.dispose();
}

class CustomSplitScreen extends StatefulWidget {
  const CustomSplitScreen({super.key});

  @override
  State<CustomSplitScreen> createState() => _CustomSplitScreenState();
}

class _CustomSplitScreenState extends State<CustomSplitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'My Split');
  final List<_DayDraft> _days = [_DayDraft(), _DayDraft()];
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    for (final day in _days) {
      day.dispose();
    }
    super.dispose();
  }

  void _addDay() => setState(() => _days.add(_DayDraft()));

  void _removeDay(_DayDraft day) {
    setState(() {
      _days.remove(day);
      day.dispose();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final dayNames = _days
        .map((d) => d.controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (dayNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one day')),
      );
      return;
    }

    setState(() => _saving = true);

    final split = WorkoutSplit(
      type: SplitType.custom,
      name: _nameController.text.trim(),
      dayNames: dayNames,
      createdAt: DateTime.now(),
    );

    await context.read<TrainingRepository>().saveSplit(split);

    if (mounted) {
      Navigator.of(context).popUntil(
        (route) => route.settings.name == 'training' || route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom split')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Split name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a name'
                    : null,
              ),
              const SizedBox(height: 24),
              Text('Days', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ..._days.map(
                (day) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: day.controller,
                          textCapitalization: TextCapitalization.words,
                          decoration:
                              const InputDecoration(labelText: 'Day name'),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _days.length > 1 ? () => _removeDay(day) : null,
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove day',
                      ),
                    ],
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _addDay,
                icon: const Icon(Icons.add),
                label: const Text('Add day'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Save split'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
