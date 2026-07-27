import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../repositories/nutrition_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../health/health_service.dart';
import '../nutrition/target_calories.dart';

/// Syncs a small snapshot of today's nutrition to the Android home-screen
/// widget (`CalorieWidgetProvider.kt`). Android-only — a no-op elsewhere,
/// since there's no equivalent widget extension set up for iOS/desktop.
///
/// Best-effort: a failed sync should never affect the app itself, so every
/// platform-channel call is wrapped and logged rather than thrown, matching
/// `NotificationService`/`HealthService`'s style.
class HomeWidgetService {
  HomeWidgetService._();

  static final HomeWidgetService instance = HomeWidgetService._();

  static const _androidProviderName = 'CalorieWidgetProvider';

  Future<void> syncTodayCalories({
    required NutritionRepository nutrition,
    required ProfileRepository profile,
    required TrainingRepository training,
    required SettingsRepository settings,
  }) async {
    if (!Platform.isAndroid) return;

    try {
      final now = DateTime.now();
      final todayEntries = nutrition.entries.where(
        (e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day,
      );

      var calories = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0;
      for (final entry in todayEntries) {
        calories += entry.calories;
        protein += entry.proteinG;
        carbs += entry.carbsG;
        fat += entry.fatG;
      }

      final healthActivity = settings.healthSyncEnabled
          ? await HealthService.instance.averageDailyActivity()
          : null;

      final target = computeTargetCalories(
        profile: profile.profile,
        goal: nutrition.goal,
        currentWeightKg: training.latestWeightKg,
        sessions: training.sessions,
        avgActiveEnergyKcal: healthActivity?.avgActiveEnergyKcal,
      );

      await HomeWidget.saveWidgetData<int>('calories_logged', calories.round());
      await HomeWidget.saveWidgetData<int>('protein_g', protein.round());
      await HomeWidget.saveWidgetData<int>('carbs_g', carbs.round());
      await HomeWidget.saveWidgetData<int>('fat_g', fat.round());
      await HomeWidget.saveWidgetData<int>(
        'calories_target',
        target == null ? 0 : ((target.low + target.high) / 2).round(),
      );

      await HomeWidget.updateWidget(androidName: _androidProviderName);
    } catch (e) {
      debugPrint('HomeWidgetService: sync failed: $e');
    }
  }
}
