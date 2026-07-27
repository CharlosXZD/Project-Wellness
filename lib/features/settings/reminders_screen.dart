import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/notification_service.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/settings_repository.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Future<void> _handleToggle(
    BuildContext context, {
    required bool enabling,
    required Future<void> Function(bool) setEnabled,
  }) async {
    if (enabling) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.notificationsOff),
            ),
          );
        }
        return;
      }
    }
    await setEnabled(enabling);
  }

  Future<void> _pickTime(
    BuildContext context, {
    required TimeOfDay initial,
    required Future<void> Function(TimeOfDay) setTime,
  }) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      await setTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reminders)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              l10n.localOnlyNotice,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            _ReminderRow(
              title: l10n.breakfast,
              subtitle: l10n.breakfastSubtitle,
              enabled: settings.breakfastReminderEnabled,
              time: settings.breakfastReminderTime,
              onToggle: (value) => _handleToggle(
                context,
                enabling: value,
                setEnabled: settings.setBreakfastReminderEnabled,
              ),
              onPickTime: () => _pickTime(
                context,
                initial: settings.breakfastReminderTime,
                setTime: settings.setBreakfastReminderTime,
              ),
            ),
            const SizedBox(height: 12),
            _ReminderRow(
              title: l10n.lunch,
              subtitle: l10n.lunchSubtitle,
              enabled: settings.lunchReminderEnabled,
              time: settings.lunchReminderTime,
              onToggle: (value) => _handleToggle(
                context,
                enabling: value,
                setEnabled: settings.setLunchReminderEnabled,
              ),
              onPickTime: () => _pickTime(
                context,
                initial: settings.lunchReminderTime,
                setTime: settings.setLunchReminderTime,
              ),
            ),
            const SizedBox(height: 12),
            _ReminderRow(
              title: l10n.dinner,
              subtitle: l10n.dinnerSubtitle,
              enabled: settings.dinnerReminderEnabled,
              time: settings.dinnerReminderTime,
              onToggle: (value) => _handleToggle(
                context,
                enabling: value,
                setEnabled: settings.setDinnerReminderEnabled,
              ),
              onPickTime: () => _pickTime(
                context,
                initial: settings.dinnerReminderTime,
                setTime: settings.setDinnerReminderTime,
              ),
            ),
            const SizedBox(height: 12),
            _ReminderRow(
              title: l10n.weighIn,
              subtitle: l10n.weighInSubtitle,
              enabled: settings.weighInReminderEnabled,
              time: settings.weighInReminderTime,
              onToggle: (value) => _handleToggle(
                context,
                enabling: value,
                setEnabled: settings.setWeighInReminderEnabled,
              ),
              onPickTime: () => _pickTime(
                context,
                initial: settings.weighInReminderTime,
                setTime: settings.setWeighInReminderTime,
              ),
            ),
            const SizedBox(height: 12),
            _ReminderRow(
              title: l10n.workout,
              subtitle: l10n.workoutSubtitle,
              enabled: settings.workoutReminderEnabled,
              time: settings.workoutReminderTime,
              onToggle: (value) => _handleToggle(
                context,
                enabling: value,
                setEnabled: settings.setWorkoutReminderEnabled,
              ),
              onPickTime: () => _pickTime(
                context,
                initial: settings.workoutReminderTime,
                setTime: settings.setWorkoutReminderTime,
              ),
            ),
            const SizedBox(height: 12),
            _ReminderRow(
              title: l10n.backup,
              subtitle: l10n.backupSubtitle,
              enabled: settings.backupReminderEnabled,
              time: settings.backupReminderTime,
              onToggle: (value) => _handleToggle(
                context,
                enabling: value,
                setEnabled: settings.setBackupReminderEnabled,
              ),
              onPickTime: () => _pickTime(
                context,
                initial: settings.backupReminderTime,
                setTime: settings.setBackupReminderTime,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  const _ReminderRow({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                Switch(value: enabled, onChanged: onToggle),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 4),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onPickTime,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        time.format(context),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
