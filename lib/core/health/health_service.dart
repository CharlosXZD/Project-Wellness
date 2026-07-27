import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../../models/workout_session.dart';

/// Result of [HealthService.averageDailyActivity] — average daily steps and
/// active energy burned over the requested window.
class HealthActivitySummary {
  final int avgSteps;
  final double avgActiveEnergyKcal;

  const HealthActivitySummary({
    required this.avgSteps,
    required this.avgActiveEnergyKcal,
  });
}

/// Bridges to Apple Health (iOS) / Health Connect (Android) via `package:health`.
///
/// Write-out (weight, workouts) is best-effort and silent on failure — a
/// failed Health write should never block logging weight or finishing a
/// workout in-app, mirroring the defensive style already used by
/// `AppIconSwitcher`/`NotificationService`. Read-in (steps, active energy)
/// returns `null` on any failure/unavailability; callers must treat `null` as
/// "fall back to the existing heuristic," not as an error.
class HealthService {
  HealthService._();

  static final HealthService instance = HealthService._();

  final _health = Health();
  bool _configured = false;

  // Cached so `TrainingRepository` (which has no reference to
  // `SettingsRepository`) can check whether sync is on before writing,
  // without the two repositories depending on each other — same pattern as
  // `NotificationService`'s cached workout-reminder state.
  bool _syncEnabled = false;
  bool get syncEnabled => _syncEnabled;
  void setSyncEnabled(bool enabled) => _syncEnabled = enabled;

  static const _writeTypes = [HealthDataType.WEIGHT, HealthDataType.WORKOUT];
  static const _writePermissions = [
    HealthDataAccess.WRITE,
    HealthDataAccess.WRITE,
  ];
  static const _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];
  static const _readPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Requests read (steps, active energy) + write (weight, workouts)
  /// authorization in one call. Call lazily, the first time the user enables
  /// the sync toggle — not at app launch.
  Future<bool> requestPermissions() async {
    try {
      await _configure();
      return await _health.requestAuthorization(
        [..._readTypes, ..._writeTypes],
        permissions: [..._readPermissions, ..._writePermissions],
      );
    } catch (e) {
      debugPrint('HealthService: permission request failed: $e');
      return false;
    }
  }

  Future<void> writeWeight(double kg, DateTime date) async {
    try {
      await _configure();
      await _health.writeHealthData(
        value: kg,
        unit: HealthDataUnit.KILOGRAM,
        type: HealthDataType.WEIGHT,
        startTime: date,
        endTime: date,
      );
    } catch (e) {
      debugPrint('HealthService: failed to write weight: $e');
    }
  }

  /// Writes a generic strength-training workout record. This app has no
  /// per-workout "type" beyond a free-text day name, so every session maps
  /// to the same generic activity type rather than guessing a sport.
  Future<void> writeWorkout(WorkoutSession session) async {
    try {
      await _configure();
      final start = session.date;
      final end = start.add(
        Duration(minutes: session.durationMinutes ?? 45),
      );
      await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING,
        start: start,
        end: end,
        title: session.name,
      );
    } catch (e) {
      debugPrint('HealthService: failed to write workout: $e');
    }
  }

  /// Average daily steps + active energy burned over the trailing [days]
  /// days, or `null` if unavailable (no permission, no data, unsupported
  /// platform). Never throws.
  Future<HealthActivitySummary?> averageDailyActivity({int days = 7}) async {
    try {
      await _configure();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final steps = await _health.getTotalStepsInInterval(start, now);

      final energyPoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: now,
      );
      final totalEnergyKcal = energyPoints.fold<double>(
        0,
        (sum, point) => sum + (point.value as NumericHealthValue).numericValue,
      );

      if (steps == null && energyPoints.isEmpty) return null;

      return HealthActivitySummary(
        avgSteps: ((steps ?? 0) / days).round(),
        avgActiveEnergyKcal: totalEnergyKcal / days,
      );
    } catch (e) {
      debugPrint('HealthService: failed to read activity data: $e');
      return null;
    }
  }
}
