import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_goal.dart';
import '../../repositories/cycle_repository.dart';
import '../../repositories/health_activity_repository.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../cycle/cycle_calculator.dart';
import 'target_calories.dart';

/// Luteal-phase kcal bump currently in effect, or null — only when cycle
/// tracking *and* its calorie adjustment are both on.
int? currentCycleAdjustmentKcal(BuildContext context) {
  final settings = context.watch<SettingsRepository>();
  if (!settings.cycleTrackingEnabled || !settings.cycleAdjustCalories) return null;
  final cycle = context.watch<CycleRepository>();
  return lutealCalorieAdjustment(currentCycleStatus(cycle.entries.map((e) => e.date).toList())?.phase);
}

/// Today's [DailyTarget] from the app's live data — the one entry point
/// screens use (the home widget calls [computeDailyTarget] directly). Pass
/// [goal] to preview an unsaved goal, [weightKg] to project to another
/// weight. Watches every repository involved, so callers rebuild whenever
/// any input changes.
DailyTarget? watchDailyTarget(
  BuildContext context, {
  NutritionGoal? goal,
  double? weightKg,
}) {
  final profile = context.watch<ProfileRepository>().profile;
  final nutrition = context.watch<NutritionRepository>();
  final training = context.watch<TrainingRepository>();
  final health = context.watch<HealthActivityRepository>().summary;

  return computeDailyTarget(
    profile: profile,
    goal: goal ?? nutrition.goal,
    weightEntries: training.weightEntries,
    sessions: training.sessions,
    foodEntries: nutrition.entries,
    health: health,
    cycleAdjustmentKcal: currentCycleAdjustmentKcal(context),
    weightKgOverride: weightKg,
  );
}
