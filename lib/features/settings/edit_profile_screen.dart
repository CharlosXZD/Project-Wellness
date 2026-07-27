import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/units/units.dart';
import '../../models/user_profile.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _feetController;
  late final TextEditingController _inchesController;
  late DateTime _dateOfBirth;
  Sex? _sex;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileRepository>().profile!;
    final unitSystem = context.read<SettingsRepository>().unitSystem;

    _nameController = TextEditingController(text: profile.name);
    _dateOfBirth = profile.dateOfBirth;
    _sex = profile.sex;

    if (unitSystem == UnitSystem.metric) {
      _weightController =
          TextEditingController(text: profile.weightKg.toStringAsFixed(1));
      _heightController =
          TextEditingController(text: profile.heightCm.toStringAsFixed(0));
      _feetController = TextEditingController();
      _inchesController = TextEditingController();
    } else {
      _weightController = TextEditingController(
        text: Units.kgToLbs(profile.weightKg).toStringAsFixed(1),
      );
      final totalInches = Units.cmToInches(profile.heightCm).round();
      _feetController = TextEditingController(text: '${totalInches ~/ 12}');
      _inchesController = TextEditingController(text: '${totalInches % 12}');
      _heightController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(now.year - 130),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select male or female')),
      );
      return;
    }

    setState(() => _saving = true);

    final profileRepo = context.read<ProfileRepository>();
    final unitSystem = context.read<SettingsRepository>().unitSystem;
    final current = profileRepo.profile!;

    final heightCm = unitSystem == UnitSystem.metric
        ? double.parse(_heightController.text.trim())
        : Units.feetInchesToCm(
            int.parse(_feetController.text.trim()),
            double.tryParse(_inchesController.text.trim()) ?? 0,
          );
    final weightKg = Units.parseWeightToKg(
      _weightController.text.trim(),
      unitSystem,
    )!;

    final updated = current.copyWith(
      name: _nameController.text.trim(),
      dateOfBirth: _dateOfBirth,
      heightCm: heightCm,
      weightKg: weightKg,
      sex: _sex,
    );

    await profileRepo.saveProfile(updated);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final unitSystem = context.watch<SettingsRepository>().unitSystem;
    final isMetric = unitSystem == UnitSystem.metric;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _pickDateOfBirth,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    child: Text(DateFormat.yMMMd().format(_dateOfBirth)),
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<Sex>(
                  segments: const [
                    ButtonSegment(value: Sex.male, label: Text('Male')),
                    ButtonSegment(value: Sex.female, label: Text('Female')),
                  ],
                  selected: {_sex ?? Sex.male},
                  emptySelectionAllowed: true,
                  onSelectionChanged: (selection) =>
                      setState(() => _sex = selection.isEmpty ? null : selection.first),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Weight (${Units.weightUnitLabel(unitSystem)})',
                        ),
                        validator: (value) {
                          final weight = double.tryParse(value?.trim() ?? '');
                          if (weight == null || weight <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (isMetric)
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Height (cm)'),
                          validator: (value) {
                            final height = double.tryParse(value?.trim() ?? '');
                            if (height == null || height <= 0) return 'Invalid';
                            return null;
                          },
                        ),
                      )
                    else ...[
                      Expanded(
                        child: TextFormField(
                          controller: _feetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Height (ft)'),
                          validator: (value) {
                            final feet = int.tryParse(value?.trim() ?? '');
                            if (feet == null || feet <= 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _inchesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'in'),
                          validator: (value) {
                            final inches = double.tryParse(value?.trim() ?? '0');
                            if (inches == null || inches < 0 || inches >= 12) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),
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
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
