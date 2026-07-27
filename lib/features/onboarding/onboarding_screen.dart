import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/nutrition/bmr_calculator.dart';
import '../../core/units/units.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  DateTime? _dateOfBirth;
  Sex? _sex;
  SelfReportedActivityLevel? _activityLevel;
  bool _saving = false;

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
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 130),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_sex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectSexError)),
      );
      return;
    }
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectDobError)),
      );
      return;
    }

    setState(() => _saving = true);

    final unitSystem = context.read<SettingsRepository>().unitSystem;
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

    final profile = UserProfile(
      name: _nameController.text.trim(),
      dateOfBirth: _dateOfBirth!,
      heightCm: heightCm,
      weightKg: weightKg,
      sex: _sex,
      createdAt: DateTime.now(),
      initialActivityLevel: _activityLevel,
    );

    await context.read<ProfileRepository>().saveProfile(profile);

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitSystem = context.watch<SettingsRepository>().unitSystem;
    final isMetric = unitSystem == UnitSystem.metric;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      l10n.onboardingTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.onboardingSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: l10n.nameLabel),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? l10n.nameRequiredError
                          : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickDateOfBirth,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.dobLabel,
                          suffixIcon: const Icon(Icons.calendar_month),
                        ),
                        child: Text(
                          _dateOfBirth == null
                              ? l10n.selectDate
                              : DateFormat.yMMMd().format(_dateOfBirth!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<Sex>(
                      segments: [
                        ButtonSegment(value: Sex.male, label: Text(l10n.male)),
                        ButtonSegment(value: Sex.female, label: Text(l10n.female)),
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
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: InputDecoration(
                              labelText: l10n.weightLabelWithUnit(
                                Units.weightUnitLabel(unitSystem),
                              ),
                            ),
                            validator: (value) {
                              final weight = double.tryParse(value?.trim() ?? '');
                              if (weight == null || weight <= 0) {
                                return l10n.invalid;
                              }
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
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: l10n.heightCmLabel,
                              ),
                              validator: (value) {
                                final height = double.tryParse(value?.trim() ?? '');
                                if (height == null || height <= 0) {
                                  return l10n.invalid;
                                }
                                return null;
                              },
                            ),
                          )
                        else ...[
                          Expanded(
                            child: TextFormField(
                              controller: _feetController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.heightFtLabel,
                              ),
                              validator: (value) {
                                final feet = int.tryParse(value?.trim() ?? '');
                                if (feet == null || feet <= 0) return l10n.invalid;
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _inchesController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.inLabel,
                              ),
                              validator: (value) {
                                final inches = double.tryParse(value?.trim() ?? '0');
                                if (inches == null || inches < 0 || inches >= 12) {
                                  return l10n.invalid;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.activityLevelLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.activityLevelSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<SelfReportedActivityLevel>(
                      groupValue: _activityLevel,
                      onChanged: (value) => setState(() => _activityLevel = value),
                      child: Column(
                        children: SelfReportedActivityLevel.values
                            .map(
                              (level) => RadioListTile<SelfReportedActivityLevel>(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: Text(level.label),
                                subtitle: Text(level.description),
                                value: level,
                              ),
                            )
                            .toList(),
                      ),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(l10n.getStarted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
