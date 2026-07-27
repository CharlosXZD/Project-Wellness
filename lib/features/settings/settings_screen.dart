import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/health/health_service.dart';
import '../../core/security/app_lock_service.dart';
import '../../core/sharing/backup_service.dart';
import '../../core/sharing/share_codec.dart';
import '../../core/theme/app_theme.dart';
import '../../core/units/units.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/rect_button.dart';
import '../nutrition/personal_foods_screen.dart';
import '../security/pin_setup_screen.dart';
import '../training/personal_exercises_screen.dart';
import 'cycle_screen.dart';
import 'edit_profile_screen.dart';
import 'reminders_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String get _backupFileName =>
      'project_wellness_backup_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.txt';

  /// Writes the backup straight to wherever the user picks in the native
  /// "Save As" dialog (Files/Downloads/an SD card/etc.) — no share sheet
  /// involved, so it lands directly on the device instead of needing a
  /// second app to receive it.
  Future<void> _saveDataToDevice(BuildContext context) async {
    final blob = await exportBackup();
    final path = await FilePicker.saveFile(
      fileName: _backupFileName,
      bytes: Uint8List.fromList(utf8.encode(blob)),
    );
    if (!context.mounted || path == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup saved')),
    );
  }

  Future<void> _shareData(BuildContext context) async {
    final blob = await exportBackup();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$_backupFileName');
    await file.writeAsString(blob);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Project Wellness backup',
      ),
    );
  }

  Future<void> _importData(BuildContext context) async {
    // FileType.any (rather than filtering to a custom "txt" extension)
    // is what makes the native picker show a real "Browse" view across
    // Files/iCloud/Downloads/etc. — the extension filter used to restrict
    // it to a narrow, easy-to-miss list on some devices.
    final result = await FilePicker.pickFiles(type: FileType.any);
    final path = result?.files.single.path;
    if (path == null || !context.mounted) return;

    final content = await File(path).readAsString();

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.replaceAllDataTitle),
        content: Text(l10n.replaceAllDataContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.replace),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await importBackup(content);
    } on ShareCodeException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    if (!context.mounted) return;
    final profileRepo = context.read<ProfileRepository>();
    final trainingRepo = context.read<TrainingRepository>();
    final nutritionRepo = context.read<NutritionRepository>();
    await profileRepo.load();
    await trainingRepo.load();
    await nutritionRepo.load();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dataRestored)),
      );
    }
  }

  Future<void> _deleteAllData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAllDataTitle),
        content: Text(l10n.deleteAllDataContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteEverything),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await deleteAllData();

    if (!context.mounted) return;
    final profileRepo = context.read<ProfileRepository>();
    final trainingRepo = context.read<TrainingRepository>();
    final nutritionRepo = context.read<NutritionRepository>();
    await profileRepo.load();
    await trainingRepo.load();
    await nutritionRepo.load();

    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = context.watch<ProfileRepository>().profile;
    final unitSystem = context.watch<SettingsRepository>().unitSystem;
    final scheme = Theme.of(context).colorScheme;
    final healthServiceName =
        Platform.isIOS ? l10n.appleHealth : l10n.healthConnect;
    final biometricMethodName =
        Platform.isIOS ? l10n.faceIdTouchId : l10n.fingerprintOrFace;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (profile != null) ...[
              Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${profile.age} yrs · ${Units.formatHeight(profile.heightCm, unitSystem)} · '
                '${Units.formatWeight(profile.weightKg, unitSystem)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              RectButton(
                icon: Icons.edit_outlined,
                title: l10n.editProfile,
                subtitle: l10n.editProfileSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
              const SizedBox(height: 12),
              RectButton(
                icon: Icons.notifications_outlined,
                title: l10n.reminders,
                subtitle: l10n.remindersSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RemindersScreen()),
                ),
              ),
              const SizedBox(height: 12),
              RectButton(
                icon: Icons.calendar_month_outlined,
                title: l10n.cycleTracking,
                subtitle: l10n.cycleTrackingSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CycleScreen()),
                ),
              ),
              const SizedBox(height: 12),
              RectButton(
                icon: Icons.fitness_center_outlined,
                title: l10n.personalExercises,
                subtitle: l10n.personalExercisesSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PersonalExercisesScreen()),
                ),
              ),
              const SizedBox(height: 12),
              RectButton(
                icon: Icons.restaurant_outlined,
                title: l10n.personalFoods,
                subtitle: l10n.personalFoodsSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PersonalFoodsScreen()),
                ),
              ),
              const SizedBox(height: 28),
            ],
            Text(l10n.appearance,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.appearanceDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            const _ThemeModePicker(),
            const SizedBox(height: 16),
            const _ThemePicker(),
            const SizedBox(height: 28),
            Text(l10n.units, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.unitsDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            const _UnitSystemPicker(),
            const SizedBox(height: 28),
            Text(
              healthServiceName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.healthSyncDescription(healthServiceName),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            const _HealthSyncToggle(),
            const SizedBox(height: 28),
            Text(l10n.privacy, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.privacyDescription(biometricMethodName),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            const _AppLockToggle(),
            const _PinBackupRow(),
            const SizedBox(height: 28),
            Text('Experimental',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Early features that are still being tuned.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            const _MuscleRankToggle(),
            const SizedBox(height: 28),
            Text(l10n.yourData, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.yourDataDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            RectButton(
              icon: Icons.save_alt_outlined,
              title: l10n.exportMyData,
              subtitle: l10n.exportMyDataSubtitle,
              onTap: () => _saveDataToDevice(context),
            ),
            const SizedBox(height: 12),
            RectButton(
              icon: Icons.ios_share,
              title: l10n.shareBackupFile,
              subtitle: l10n.shareBackupFileSubtitle,
              onTap: () => _shareData(context),
            ),
            const SizedBox(height: 12),
            RectButton(
              icon: Icons.download_outlined,
              title: l10n.importData,
              subtitle: l10n.importDataSubtitle,
              onTap: () => _importData(context),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.dangerZone,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.error,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.dangerZoneDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Material(
              color: scheme.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _deleteAllData(context),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: scheme.error,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.delete_forever_outlined,
                            color: scheme.onError),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.deleteAllData,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: scheme.onErrorContainer,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.deleteAllDataCardSubtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onErrorContainer,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

String _themeSeedLabel(AppLocalizations l10n, AppThemeSeed seed) =>
    switch (seed) {
      AppThemeSeed.classic => l10n.themeClassic,
      AppThemeSeed.pink => l10n.themePink,
    };

String _themeModeLabel(AppLocalizations l10n, AppThemeMode mode) =>
    switch (mode) {
      AppThemeMode.system => l10n.themeModeSystem,
      AppThemeMode.light => l10n.themeModeLight,
      AppThemeMode.dark => l10n.themeModeDark,
    };

String _unitSystemLabel(AppLocalizations l10n, UnitSystem system) =>
    switch (system) {
      UnitSystem.metric => l10n.unitSystemMetric,
      UnitSystem.imperial => l10n.unitSystemImperial,
    };

class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsRepository>();
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: AppThemeSeed.values.map((seed) {
        final selected = settings.themeSeed == seed;
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.read<SettingsRepository>().setThemeSeed(seed),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: seed.seedColor,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: scheme.onSurface, width: 3)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  _themeSeedLabel(l10n, seed),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: selected ? FontWeight.w700 : null,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ThemeModePicker extends StatelessWidget {
  const _ThemeModePicker();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsRepository>();

    return SegmentedButton<AppThemeMode>(
      segments: AppThemeMode.values
          .map(
            (mode) => ButtonSegment(
              value: mode,
              label: Text(_themeModeLabel(l10n, mode)),
              icon: Icon(mode.icon),
            ),
          )
          .toList(),
      selected: {settings.themeMode},
      onSelectionChanged: (selection) =>
          context.read<SettingsRepository>().setThemeMode(selection.first),
    );
  }
}

class _UnitSystemPicker extends StatelessWidget {
  const _UnitSystemPicker();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsRepository>();

    return SegmentedButton<UnitSystem>(
      segments: UnitSystem.values
          .map((system) => ButtonSegment(
                value: system,
                label: Text(_unitSystemLabel(l10n, system)),
              ))
          .toList(),
      selected: {settings.unitSystem},
      onSelectionChanged: (selection) =>
          context.read<SettingsRepository>().setUnitSystem(selection.first),
    );
  }
}

class _MuscleRankToggle extends StatelessWidget {
  const _MuscleRankToggle();

  @override
  Widget build(BuildContext context) {
    final enabled = context.watch<SettingsRepository>().muscleRankEnabled;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Body Rank',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    'A per-muscle rank diagram based on your training volume.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: (value) => context
                  .read<SettingsRepository>()
                  .setMuscleRankEnabled(value),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthSyncToggle extends StatelessWidget {
  const _HealthSyncToggle();

  Future<void> _handleToggle(BuildContext context, bool enabling) async {
    final settings = context.read<SettingsRepository>();
    final l10n = AppLocalizations.of(context)!;
    final serviceName = Platform.isIOS ? l10n.appleHealth : l10n.healthConnect;
    if (enabling) {
      final granted = await HealthService.instance.requestPermissions();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.healthPermissionDenied(serviceName))),
          );
        }
        return;
      }
    }
    await settings.setHealthSyncEnabled(enabling);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = context.watch<SettingsRepository>().healthSyncEnabled;
    final scheme = Theme.of(context).colorScheme;
    final serviceName = Platform.isIOS ? l10n.appleHealth : l10n.healthConnect;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.syncWithService(serviceName),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Switch(
              value: enabled,
              onChanged: (value) => _handleToggle(context, value),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppLockToggle extends StatelessWidget {
  const _AppLockToggle();

  Future<void> _handleToggle(BuildContext context, bool enabling) async {
    final settings = context.read<SettingsRepository>();
    final l10n = AppLocalizations.of(context)!;
    if (enabling) {
      final supported = await AppLockService.instance.isDeviceSupported();
      if (!supported) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noBiometricsSetUp)),
          );
        }
        return;
      }
      final authenticated = await AppLockService.instance.authenticate();
      if (!authenticated) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.authenticationFailed)),
          );
        }
        return;
      }
    }
    await settings.setAppLockEnabled(enabling);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = context.watch<SettingsRepository>().appLockEnabled;
    final scheme = Theme.of(context).colorScheme;
    final methodName =
        Platform.isIOS ? l10n.faceIdTouchId : l10n.fingerprintSlashFace;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.requireBiometric(methodName),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Switch(
              value: enabled,
              onChanged: (value) => _handleToggle(context, value),
            ),
          ],
        ),
      ),
    );
  }
}

/// A PIN backup only makes sense once biometric app lock is on — it's a
/// fallback for when biometric fails, not a mode picked instead of it (see
/// `AppLockScreen`'s "Use PIN instead" button).
class _PinBackupRow extends StatelessWidget {
  const _PinBackupRow();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>();
    if (!settings.appLockEnabled) return const SizedBox.shrink();

    final hasPin = settings.pinHash != null;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: RectButton(
        icon: Icons.dialpad,
        title: hasPin ? 'Change PIN backup' : 'Set up PIN backup',
        subtitle: hasPin
            ? 'Used on the lock screen if biometric unlock fails'
            : 'Add a 4-digit fallback for when biometric unlock fails',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PinSetupScreen()),
        ),
        outlined: hasPin,
      ),
    );
  }
}
