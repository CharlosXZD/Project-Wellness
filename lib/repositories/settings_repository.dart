import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../core/db/database_helper.dart';
import '../core/health/health_service.dart';
import '../core/notifications/notification_service.dart';
import '../core/platform/app_icon_switcher.dart';
import '../core/theme/app_theme.dart';
import '../core/units/units.dart';

/// App-level device preferences — theme, appearance, units, reminders. Kept
/// separate from [ProfileRepository]/etc. and out of backup/restore and
/// "delete all data": these are display/device preferences, not user
/// content.
class SettingsRepository extends ChangeNotifier {
  AppThemeSeed _themeSeed = AppThemeSeed.classic;
  AppThemeMode _themeMode = AppThemeMode.system;
  UnitSystem _unitSystem = UnitSystem.metric;
  bool _loaded = false;

  bool _breakfastReminderEnabled = false;
  TimeOfDay _breakfastReminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _lunchReminderEnabled = false;
  TimeOfDay _lunchReminderTime = const TimeOfDay(hour: 13, minute: 0);
  bool _dinnerReminderEnabled = false;
  TimeOfDay _dinnerReminderTime = const TimeOfDay(hour: 19, minute: 0);
  bool _weighInReminderEnabled = false;
  TimeOfDay _weighInReminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _workoutReminderEnabled = false;
  TimeOfDay _workoutReminderTime = const TimeOfDay(hour: 18, minute: 0);
  bool _backupReminderEnabled = false;
  TimeOfDay _backupReminderTime = const TimeOfDay(hour: 10, minute: 0);
  bool _healthSyncEnabled = false;
  bool _appLockEnabled = false;
  bool _cycleTrackingEnabled = false;
  bool _cycleAdjustCalories = false;
  bool _muscleRankEnabled = false;
  String? _pinHash;
  String? _pinSalt;

  AppThemeSeed get themeSeed => _themeSeed;
  AppThemeMode get themeMode => _themeMode;
  UnitSystem get unitSystem => _unitSystem;
  bool get isLoaded => _loaded;

  bool get breakfastReminderEnabled => _breakfastReminderEnabled;
  TimeOfDay get breakfastReminderTime => _breakfastReminderTime;
  bool get lunchReminderEnabled => _lunchReminderEnabled;
  TimeOfDay get lunchReminderTime => _lunchReminderTime;
  bool get dinnerReminderEnabled => _dinnerReminderEnabled;
  TimeOfDay get dinnerReminderTime => _dinnerReminderTime;
  bool get weighInReminderEnabled => _weighInReminderEnabled;
  TimeOfDay get weighInReminderTime => _weighInReminderTime;
  bool get workoutReminderEnabled => _workoutReminderEnabled;
  TimeOfDay get workoutReminderTime => _workoutReminderTime;
  bool get backupReminderEnabled => _backupReminderEnabled;
  TimeOfDay get backupReminderTime => _backupReminderTime;
  bool get healthSyncEnabled => _healthSyncEnabled;
  bool get appLockEnabled => _appLockEnabled;
  bool get cycleTrackingEnabled => _cycleTrackingEnabled;
  bool get cycleAdjustCalories => _cycleAdjustCalories;
  bool get muscleRankEnabled => _muscleRankEnabled;
  String? get pinHash => _pinHash;
  String? get pinSalt => _pinSalt;

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('app_settings', where: 'id = 1', limit: 1);
    if (rows.isNotEmpty) {
      final row = rows.first;
      _themeSeed = AppThemeSeed.values.firstWhere(
        (t) => t.name == row['theme_seed'],
        orElse: () => AppThemeSeed.classic,
      );
      _themeMode = AppThemeMode.values.firstWhere(
        (t) => t.name == row['theme_mode'],
        orElse: () => AppThemeMode.system,
      );
      _unitSystem = UnitSystem.values.firstWhere(
        (t) => t.name == row['unit_system'],
        orElse: () => UnitSystem.metric,
      );
      _breakfastReminderEnabled = (row['breakfast_reminder_enabled'] as int?) == 1;
      _breakfastReminderTime = _minutesToTime(row['breakfast_reminder_minutes'], _breakfastReminderTime);
      _lunchReminderEnabled = (row['lunch_reminder_enabled'] as int?) == 1;
      _lunchReminderTime = _minutesToTime(row['lunch_reminder_minutes'], _lunchReminderTime);
      _dinnerReminderEnabled = (row['dinner_reminder_enabled'] as int?) == 1;
      _dinnerReminderTime = _minutesToTime(row['dinner_reminder_minutes'], _dinnerReminderTime);
      _weighInReminderEnabled = (row['weighin_reminder_enabled'] as int?) == 1;
      _weighInReminderTime = _minutesToTime(row['weighin_reminder_minutes'], _weighInReminderTime);
      _workoutReminderEnabled = (row['workout_reminder_enabled'] as int?) == 1;
      _workoutReminderTime = _minutesToTime(row['workout_reminder_minutes'], _workoutReminderTime);
      _backupReminderEnabled = (row['backup_reminder_enabled'] as int?) == 1;
      _backupReminderTime = _minutesToTime(row['backup_reminder_minutes'], _backupReminderTime);
      _healthSyncEnabled = (row['health_sync_enabled'] as int?) == 1;
      _appLockEnabled = (row['app_lock_enabled'] as int?) == 1;
      _cycleTrackingEnabled = (row['cycle_tracking_enabled'] as int?) == 1;
      _cycleAdjustCalories = (row['cycle_adjust_calories'] as int?) == 1;
      _muscleRankEnabled = (row['muscle_rank_enabled'] as int?) == 1;
      _pinHash = row['pin_hash'] as String?;
      _pinSalt = row['pin_salt'] as String?;
    }
    _loaded = true;
    notifyListeners();
    // Reconcile the home-screen icon with the persisted choice — cheap and
    // idempotent, and covers cases where the OS icon fell out of sync (e.g.
    // after a reinstall resets iOS/Android back to the primary icon).
    unawaited(AppIconSwitcher.setIcon(_themeSeed));
    // Re-arm every reminder from persisted settings on every app launch —
    // also what recovers from the OS clearing scheduled alarms on reboot.
    unawaited(_syncReminders());
    HealthService.instance.setSyncEnabled(_healthSyncEnabled);
  }

  Future<void> _syncReminders() async {
    final notifications = NotificationService.instance;
    await (_breakfastReminderEnabled
        ? notifications.scheduleBreakfastReminder(_breakfastReminderTime)
        : notifications.cancelBreakfastReminder());
    await (_lunchReminderEnabled
        ? notifications.scheduleLunchReminder(_lunchReminderTime)
        : notifications.cancelLunchReminder());
    await (_dinnerReminderEnabled
        ? notifications.scheduleDinnerReminder(_dinnerReminderTime)
        : notifications.cancelDinnerReminder());
    await (_weighInReminderEnabled
        ? notifications.scheduleWeighInReminder(_weighInReminderTime)
        : notifications.cancelWeighInReminder());
    await (_workoutReminderEnabled
        ? notifications.scheduleWorkoutReminder(_workoutReminderTime)
        : notifications.cancelWorkoutReminder());
    await (_backupReminderEnabled
        ? notifications.scheduleBackupReminder(_backupReminderTime)
        : notifications.cancelBackupReminder());
  }

  static TimeOfDay _minutesToTime(Object? minutesValue, TimeOfDay fallback) {
    if (minutesValue is! int) return fallback;
    return TimeOfDay(hour: minutesValue ~/ 60, minute: minutesValue % 60);
  }

  static int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  Future<void> setThemeSeed(AppThemeSeed seed) async {
    _themeSeed = seed;
    await _save();
    notifyListeners();
    unawaited(AppIconSwitcher.setIcon(seed));
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _save();
    notifyListeners();
  }

  Future<void> setUnitSystem(UnitSystem system) async {
    _unitSystem = system;
    await _save();
    notifyListeners();
  }

  Future<void> setBreakfastReminderEnabled(bool enabled) async {
    _breakfastReminderEnabled = enabled;
    await _save();
    notifyListeners();
    await (enabled
        ? NotificationService.instance.scheduleBreakfastReminder(_breakfastReminderTime)
        : NotificationService.instance.cancelBreakfastReminder());
  }

  Future<void> setBreakfastReminderTime(TimeOfDay time) async {
    _breakfastReminderTime = time;
    await _save();
    notifyListeners();
    if (_breakfastReminderEnabled) {
      await NotificationService.instance.scheduleBreakfastReminder(time);
    }
  }

  Future<void> setLunchReminderEnabled(bool enabled) async {
    _lunchReminderEnabled = enabled;
    await _save();
    notifyListeners();
    await (enabled
        ? NotificationService.instance.scheduleLunchReminder(_lunchReminderTime)
        : NotificationService.instance.cancelLunchReminder());
  }

  Future<void> setLunchReminderTime(TimeOfDay time) async {
    _lunchReminderTime = time;
    await _save();
    notifyListeners();
    if (_lunchReminderEnabled) {
      await NotificationService.instance.scheduleLunchReminder(time);
    }
  }

  Future<void> setDinnerReminderEnabled(bool enabled) async {
    _dinnerReminderEnabled = enabled;
    await _save();
    notifyListeners();
    await (enabled
        ? NotificationService.instance.scheduleDinnerReminder(_dinnerReminderTime)
        : NotificationService.instance.cancelDinnerReminder());
  }

  Future<void> setDinnerReminderTime(TimeOfDay time) async {
    _dinnerReminderTime = time;
    await _save();
    notifyListeners();
    if (_dinnerReminderEnabled) {
      await NotificationService.instance.scheduleDinnerReminder(time);
    }
  }

  Future<void> setWeighInReminderEnabled(bool enabled) async {
    _weighInReminderEnabled = enabled;
    await _save();
    notifyListeners();
    await (enabled
        ? NotificationService.instance.scheduleWeighInReminder(_weighInReminderTime)
        : NotificationService.instance.cancelWeighInReminder());
  }

  Future<void> setWeighInReminderTime(TimeOfDay time) async {
    _weighInReminderTime = time;
    await _save();
    notifyListeners();
    if (_weighInReminderEnabled) {
      await NotificationService.instance.scheduleWeighInReminder(time);
    }
  }

  Future<void> setWorkoutReminderEnabled(bool enabled) async {
    _workoutReminderEnabled = enabled;
    await _save();
    notifyListeners();
    await (enabled
        ? NotificationService.instance.scheduleWorkoutReminder(_workoutReminderTime)
        : NotificationService.instance.cancelWorkoutReminder());
  }

  Future<void> setWorkoutReminderTime(TimeOfDay time) async {
    _workoutReminderTime = time;
    await _save();
    notifyListeners();
    if (_workoutReminderEnabled) {
      await NotificationService.instance.scheduleWorkoutReminder(time);
    }
  }

  Future<void> setBackupReminderEnabled(bool enabled) async {
    _backupReminderEnabled = enabled;
    await _save();
    notifyListeners();
    await (enabled
        ? NotificationService.instance.scheduleBackupReminder(_backupReminderTime)
        : NotificationService.instance.cancelBackupReminder());
  }

  Future<void> setBackupReminderTime(TimeOfDay time) async {
    _backupReminderTime = time;
    await _save();
    notifyListeners();
    if (_backupReminderEnabled) {
      await NotificationService.instance.scheduleBackupReminder(time);
    }
  }

  /// Persists the sync toggle and updates `HealthService`'s cached flag.
  /// Requesting the platform permission is the caller's (UI's) job — mirrors
  /// how the Reminders screen requests notification permission before
  /// calling its `set*ReminderEnabled` setters.
  Future<void> setHealthSyncEnabled(bool enabled) async {
    _healthSyncEnabled = enabled;
    await _save();
    notifyListeners();
    HealthService.instance.setSyncEnabled(enabled);
  }

  /// Confirming the device can actually authenticate is the caller's (UI's)
  /// job before calling this — mirrors the Health Connect toggle pattern.
  Future<void> setAppLockEnabled(bool enabled) async {
    _appLockEnabled = enabled;
    await _save();
    notifyListeners();
  }

  Future<void> setCycleTrackingEnabled(bool enabled) async {
    _cycleTrackingEnabled = enabled;
    await _save();
    notifyListeners();
  }

  Future<void> setCycleAdjustCalories(bool enabled) async {
    _cycleAdjustCalories = enabled;
    await _save();
    notifyListeners();
  }

  Future<void> setMuscleRankEnabled(bool enabled) async {
    _muscleRankEnabled = enabled;
    await _save();
    notifyListeners();
  }

  /// Pass `null` for both to clear the PIN (e.g. if the user removes it).
  Future<void> setPin(String? hash, String? salt) async {
    _pinHash = hash;
    _pinSalt = salt;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'app_settings',
      {
        'id': 1,
        'theme_seed': _themeSeed.name,
        'theme_mode': _themeMode.name,
        'unit_system': _unitSystem.name,
        'breakfast_reminder_enabled': _breakfastReminderEnabled ? 1 : 0,
        'breakfast_reminder_minutes': _timeToMinutes(_breakfastReminderTime),
        'lunch_reminder_enabled': _lunchReminderEnabled ? 1 : 0,
        'lunch_reminder_minutes': _timeToMinutes(_lunchReminderTime),
        'dinner_reminder_enabled': _dinnerReminderEnabled ? 1 : 0,
        'dinner_reminder_minutes': _timeToMinutes(_dinnerReminderTime),
        'weighin_reminder_enabled': _weighInReminderEnabled ? 1 : 0,
        'weighin_reminder_minutes': _timeToMinutes(_weighInReminderTime),
        'workout_reminder_enabled': _workoutReminderEnabled ? 1 : 0,
        'workout_reminder_minutes': _timeToMinutes(_workoutReminderTime),
        'backup_reminder_enabled': _backupReminderEnabled ? 1 : 0,
        'backup_reminder_minutes': _timeToMinutes(_backupReminderTime),
        'health_sync_enabled': _healthSyncEnabled ? 1 : 0,
        'app_lock_enabled': _appLockEnabled ? 1 : 0,
        'cycle_tracking_enabled': _cycleTrackingEnabled ? 1 : 0,
        'cycle_adjust_calories': _cycleAdjustCalories ? 1 : 0,
        'muscle_rank_enabled': _muscleRankEnabled ? 1 : 0,
        'pin_hash': _pinHash,
        'pin_salt': _pinSalt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
