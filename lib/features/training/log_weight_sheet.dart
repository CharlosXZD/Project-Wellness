import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/training/medal_unlock.dart';
import '../../core/units/units.dart';
import '../../models/weight_entry.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';

/// Opens the weigh-in sheet — a new entry, or [existing] to correct/delete a
/// past one.
Future<void> showLogWeightSheet(BuildContext context, {WeightEntry? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _LogWeightSheet(existing: existing),
  );
}

/// Deletes [entry] with an "Undo" snackbar instead of a confirm dialog —
/// quick to fix a mistake, and just as quick to take it back.
Future<void> deleteWeightEntryWithUndo(BuildContext context, WeightEntry entry) async {
  final repo = context.read<TrainingRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final unitSystem = context.read<SettingsRepository>().unitSystem;
  await repo.deleteWeightEntry(entry.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Removed ${Units.formatWeight(entry.weightKg, unitSystem)} weigh-in'),
        action: SnackBarAction(label: 'Undo', onPressed: () => repo.restoreWeightEntry(entry)),
      ),
    );
}

/// A weigh-in this far from the nearest other one (in time) is almost
/// certainly a typo — real day-to-day swings are a couple of percent.
const _suspiciousChangeFraction = 0.08;

class _LogWeightSheet extends StatefulWidget {
  final WeightEntry? existing;

  const _LogWeightSheet({this.existing});

  @override
  State<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends State<_LogWeightSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _noteController;
  late DateTime _date;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final unitSystem = context.read<SettingsRepository>().unitSystem;
    _date = existing?.date ?? DateTime.now();
    _weightController = TextEditingController(
      text: existing == null
          ? ''
          : Units.formatNumber(
              unitSystem == UnitSystem.metric ? existing.weightKg : Units.kgToLbs(existing.weightKg),
            ),
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      // Keep the original time of day when only the date changes.
      _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute);
    });
  }

  /// The weigh-in closest in time to [_date], excluding the one being edited.
  WeightEntry? _nearestOtherEntry() {
    final others = context
        .read<TrainingRepository>()
        .weightEntries
        .where((e) => e.id != widget.existing?.id)
        .toList();
    if (others.isEmpty) return null;
    others.sort((a, b) =>
        a.date.difference(_date).abs().compareTo(b.date.difference(_date).abs()));
    return others.first;
  }

  Future<bool> _confirmSuspiciousChange(double newKg, UnitSystem unitSystem) async {
    final reference = _nearestOtherEntry();
    if (reference == null) return true;
    final diff = newKg - reference.weightKg;
    if (diff.abs() < reference.weightKg * _suspiciousChangeFraction) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.help_outline),
        title: const Text('Is that right?'),
        content: Text(
          '${Units.formatWeight(newKg, unitSystem)} is '
          '${Units.formatWeight(diff.abs(), unitSystem)} ${diff < 0 ? 'less' : 'more'} than your '
          '${DateFormat.MMMd().format(reference.date)} weigh-in '
          '(${Units.formatWeight(reference.weightKg, unitSystem)}). '
          'A change that big is usually a typo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Fix it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save anyway'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final unitSystem = context.read<SettingsRepository>().unitSystem;
    final weightKg = Units.parseWeightToKg(_weightController.text.trim(), unitSystem)!;
    if (!await _confirmSuspiciousChange(weightKg, unitSystem)) return;
    if (!mounted) return;

    setState(() => _saving = true);
    final entry = WeightEntry(
      id: widget.existing?.id ?? const Uuid().v4(),
      date: _date,
      weightKg: weightKg,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    final trainingRepo = context.read<TrainingRepository>();
    if (_isEditing) {
      await trainingRepo.updateWeightEntry(entry);
    } else {
      await trainingRepo.addWeightEntry(entry);
    }
    if (!mounted) return;

    await evaluateMedalsAndNotify(context);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing!;
    Navigator.of(context).pop();
    await deleteWeightEntryWithUndo(context, existing);
  }

  @override
  Widget build(BuildContext context) {
    final unitSystem = context.watch<SettingsRepository>().unitSystem;
    final isToday = DateUtils.isSameDay(_date, DateTime.now());

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Edit weigh-in' : 'Log weight',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    tooltip: 'Delete',
                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                    onPressed: _saving ? null : _delete,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              autofocus: !_isEditing,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: InputDecoration(
                labelText: 'Weight',
                suffixText: Units.weightUnitLabel(unitSystem),
              ),
              validator: (value) {
                final weight = double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
                if (weight == null || weight <= 0) return 'Enter a valid weight';
                final kg = unitSystem == UnitSystem.metric ? weight : Units.lbsToKg(weight);
                if (kg < 25 || kg > 350) return 'That weight looks out of range';
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(isToday ? 'Today' : DateFormat.yMMMEd().format(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
