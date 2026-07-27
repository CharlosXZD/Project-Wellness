import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/cycle/cycle_calculator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cycle_entry.dart';
import '../../repositories/cycle_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../widgets/cycle_phase_wheel.dart';

class CycleScreen extends StatelessWidget {
  const CycleScreen({super.key});

  Future<void> _logPeriodStart(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked == null || !context.mounted) return;
    await context.read<CycleRepository>().addEntry(
          CycleEntry(id: const Uuid().v4(), date: picked),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsRepository>();
    final cycle = context.watch<CycleRepository>();
    final trackingEnabled = settings.cycleTrackingEnabled;
    final phase = currentPhase(cycle.entries.map((e) => e.date).toList());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cycleTracking)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              l10n.cycleTrackingNotice,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            _ToggleRow(
              title: l10n.cycleTrackingEnable,
              subtitle: l10n.cycleTrackingEnableSubtitle,
              value: trackingEnabled,
              onChanged: settings.setCycleTrackingEnabled,
            ),
            if (trackingEnabled) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CyclePhaseWheel(
                  periodStarts: cycle.entries.map((e) => e.date).toList(),
                ),
              ),
              const SizedBox(height: 20),
              _PhaseCard(phase: phase),
              const SizedBox(height: 20),
              _ToggleRow(
                title: l10n.cycleAdjustCaloriesTitle,
                subtitle: l10n.cycleAdjustCaloriesSubtitle,
                value: settings.cycleAdjustCalories,
                onChanged: settings.setCycleAdjustCalories,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.cyclePeriodHistory,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: () => _logPeriodStart(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.cycleLogPeriodStart),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (cycle.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.cycleNoEntries,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                for (final entry in cycle.entries) _PeriodEntryRow(entry: entry),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final CyclePhase? phase;

  const _PhaseCard({required this.phase});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.cycleCurrentPhase, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              phase == null ? l10n.cycleNotEnoughData : _phaseLabel(l10n, phase!),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(AppLocalizations l10n, CyclePhase phase) => switch (phase) {
        CyclePhase.menstrual => l10n.cyclePhaseMenstrual,
        CyclePhase.follicular => l10n.cyclePhaseFollicular,
        CyclePhase.ovulation => l10n.cyclePhaseOvulation,
        CyclePhase.luteal => l10n.cyclePhaseLuteal,
      };
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _PeriodEntryRow extends StatelessWidget {
  final CycleEntry entry;

  const _PeriodEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, size: 10, color: Theme.of(context).colorScheme.primary),
      title: Text(DateFormat.yMMMd().format(entry.date)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: l10n.cycleDeleteEntry,
        onPressed: () => context.read<CycleRepository>().deleteEntry(entry.id),
      ),
    );
  }
}
