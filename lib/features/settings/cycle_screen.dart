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

const _phaseColors = CyclePhaseWheel.phaseColors;

class CycleScreen extends StatelessWidget {
  const CycleScreen({super.key});

  Future<void> _logPeriodStart(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<CycleRepository>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 730)),
      lastDate: now,
    );
    if (picked == null || !context.mounted) return;

    final existing = repo.entries.map((e) => e.date).toList();
    if (isNearExistingPeriodStart(existing, picked)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.cycleDuplicateTitle),
          content: Text(l10n.cycleDuplicateContent(DateFormat.yMMMd().format(picked))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.cycleLogAnyway),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await repo.addEntry(CycleEntry(id: const Uuid().v4(), date: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsRepository>();
    final cycle = context.watch<CycleRepository>();
    final trackingEnabled = settings.cycleTrackingEnabled;
    final starts = cycle.entries.map((e) => e.date).toList();
    final status = currentCycleStatus(starts);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cycleTracking)),
      floatingActionButton: trackingEnabled
          ? FloatingActionButton.extended(
              onPressed: () => _logPeriodStart(context),
              icon: const Icon(Icons.water_drop_outlined),
              label: Text(l10n.cycleLogPeriodStart),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
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
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: CyclePhaseWheel(periodStarts: starts),
              ),
              const SizedBox(height: 12),
              const _PhaseLegend(),
              const SizedBox(height: 20),
              _StatusCard(status: status, hasEntries: starts.isNotEmpty),
              if (status != null) ...[
                const SizedBox(height: 12),
                _PredictionsCard(status: status, cyclesLearned: usableCycleLengths(starts).length),
              ],
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.cycleEstimateDisclaimer,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 20),
              _ToggleRow(
                title: l10n.cycleAdjustCaloriesTitle,
                subtitle: l10n.cycleAdjustCaloriesSubtitle,
                value: settings.cycleAdjustCalories,
                onChanged: settings.setCycleAdjustCalories,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.cyclePeriodHistory,
                style: Theme.of(context).textTheme.titleMedium,
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
                for (var i = 0; i < cycle.entries.length; i++)
                  _PeriodEntryRow(
                    entry: cycle.entries[i],
                    // Entries are newest first, so the gap to the *next
                    // older* one is this cycle's length.
                    cycleDays: i + 1 < cycle.entries.length
                        ? DateUtils.dateOnly(cycle.entries[i].date)
                            .difference(DateUtils.dateOnly(cycle.entries[i + 1].date))
                            .inDays
                        : null,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

String _phaseLabel(AppLocalizations l10n, CyclePhase phase) => switch (phase) {
      CyclePhase.menstrual => l10n.cyclePhaseMenstrual,
      CyclePhase.follicular => l10n.cyclePhaseFollicular,
      CyclePhase.ovulation => l10n.cyclePhaseOvulation,
      CyclePhase.luteal => l10n.cyclePhaseLuteal,
    };

class _PhaseLegend extends StatelessWidget {
  const _PhaseLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 6,
      children: [
        for (final phase in CyclePhase.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: _phaseColors[phase], shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(_phaseLabel(l10n, phase), style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final CycleStatus? status;
  final bool hasEntries;

  const _StatusCard({required this.status, required this.hasEntries});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = this.status;

    final String headline;
    final String? detail;
    if (status == null) {
      headline = l10n.cycleNotEnoughData;
      detail = hasEntries ? l10n.cycleStaleData : null;
    } else {
      headline = _phaseLabel(l10n, status.phase);
      final daysUntil = status.daysUntilNextPeriod(DateTime.now());
      detail = status.isLate
          ? l10n.cyclePeriodLate(status.daysLate)
          : l10n.cycleNextPeriodIn(daysUntil!);
    }
    final accent = status == null ? scheme.onSurfaceVariant : _phaseColors[status.phase]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 56,
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.cycleCurrentPhase,
                      style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(headline, style: textTheme.headlineSmall),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(detail, style: textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionsCard extends StatelessWidget {
  final CycleStatus status;
  final int cyclesLearned;

  const _PredictionsCard({required this.status, required this.cyclesLearned});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.MMMd();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _PredictionRow(
              icon: Icons.event_outlined,
              label: l10n.cycleExpectedOn(date.format(status.nextPeriodStart)),
            ),
            _PredictionRow(
              icon: Icons.egg_outlined,
              label: l10n.cycleOvulationEstimate,
              value: date.format(status.ovulationDate),
            ),
            _PredictionRow(
              icon: Icons.date_range_outlined,
              label: l10n.cycleFertileWindow,
              value: '${date.format(status.fertileStart)} – ${date.format(status.fertileEnd)}',
            ),
            _PredictionRow(
              icon: Icons.loop,
              label: l10n.cycleLengthLabel,
              value: l10n.cycleLengthValue(status.cycleLength),
              caption: l10n.cycleLengthLearned(cyclesLearned),
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? caption;

  const _PredictionRow({required this.icon, required this.label, this.value, this.caption});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(label),
      subtitle: caption == null ? null : Text(caption!),
      trailing: value == null
          ? null
          : Text(value!, style: Theme.of(context).textTheme.titleSmall),
    );
  }
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _PeriodEntryRow extends StatelessWidget {
  final CycleEntry entry;
  final int? cycleDays;

  const _PeriodEntryRow({required this.entry, required this.cycleDays});

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<CycleRepository>();
    final messenger = ScaffoldMessenger.of(context);
    await repo.deleteEntry(entry.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.cycleEntryDeleted),
          action: SnackBarAction(label: l10n.undo, onPressed: () => repo.addEntry(entry)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.water_drop, size: 18, color: Color(0xFFE0574F)),
      title: Text(DateFormat.yMMMd().format(entry.date)),
      subtitle: cycleDays == null ? null : Text(l10n.cycleLengthValue(cycleDays!)),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, color: scheme.onSurfaceVariant),
        tooltip: l10n.cycleDeleteEntry,
        onPressed: () => _delete(context),
      ),
    );
  }
}
