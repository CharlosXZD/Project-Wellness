import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/cycle/cycle_calculator.dart';
import '../../core/health/health_service.dart';
import '../../core/nutrition/bmr_calculator.dart';
import '../../core/nutrition/target_calories.dart';
import '../../core/units/units.dart';
import '../../models/nutrition_goal.dart';
import '../../models/user_profile.dart';
import '../../repositories/cycle_repository.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/calorie_delta_editor.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late GoalMode _mode;
  late GoalIntensity _intensity;
  double? _customCalorieDelta;
  late final TextEditingController _targetWeightController;
  HealthActivitySummary? _healthActivity;
  late bool _preciseModeEnabled;
  JobActivityLevel? _jobActivityLevel;
  int? _exerciseDaysPerWeek;
  ExerciseIntensity? _exerciseIntensity;

  @override
  void initState() {
    super.initState();
    final goal = context.read<NutritionRepository>().goal;
    final profile = context.read<ProfileRepository>().profile;
    final unitSystem = context.read<SettingsRepository>().unitSystem;
    _mode = goal?.mode ?? GoalMode.maintain;
    _intensity = goal?.intensity ?? GoalIntensity.moderate;
    _customCalorieDelta = goal?.customCalorieDelta;
    _preciseModeEnabled = profile?.preciseCalorieTrackingEnabled ?? false;
    _jobActivityLevel = profile?.jobActivityLevel;
    _exerciseDaysPerWeek = profile?.exerciseDaysPerWeek;
    _exerciseIntensity = profile?.exerciseIntensity;
    _targetWeightController = TextEditingController(
      text: goal?.targetWeightKg == null
          ? ''
          : (unitSystem == UnitSystem.metric
                  ? goal!.targetWeightKg!
                  : Units.kgToLbs(goal!.targetWeightKg!))
              .toStringAsFixed(1),
    );
    if (context.read<SettingsRepository>().healthSyncEnabled) {
      HealthService.instance.averageDailyActivity().then((summary) {
        if (mounted) setState(() => _healthActivity = summary);
      });
    }
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final unitSystem = context.read<SettingsRepository>().unitSystem;
    final targetWeight = Units.parseWeightToKg(
      _targetWeightController.text.trim(),
      unitSystem,
    );
    await context.read<NutritionRepository>().saveGoal(
          NutritionGoal(
            mode: _mode,
            intensity: _intensity,
            targetWeightKg: targetWeight,
            customCalorieDelta: _customCalorieDelta,
            updatedAt: DateTime.now(),
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal saved')),
      );
    }
  }

  /// Precise-activity fields save immediately on change, like a settings
  /// toggle, rather than being batched into the "Save goal" button below —
  /// they describe the person, not this particular goal.
  Future<void> _savePreciseActivity() async {
    final repo = context.read<ProfileRepository>();
    final profile = repo.profile;
    if (profile == null) return;
    await repo.saveProfile(
      profile.copyWith(
        preciseCalorieTrackingEnabled: _preciseModeEnabled,
        jobActivityLevel: _jobActivityLevel,
        exerciseDaysPerWeek: _exerciseDaysPerWeek,
        exerciseIntensity: _exerciseIntensity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileRepository>().profile;
    final unitSystem = context.watch<SettingsRepository>().unitSystem;

    return Scaffold(
      appBar: AppBar(title: const Text('Goals & BMR')),
      body: profile == null
          ? const SizedBox.shrink()
          : profile.sex == null
              ? _MissingSexPrompt(profile: profile)
              : _GoalsBody(
                  profile: profile,
                  mode: _mode,
                  intensity: _intensity,
                  customCalorieDelta: _customCalorieDelta,
                  targetWeightController: _targetWeightController,
                  unitSystem: unitSystem,
                  healthActivity: _healthActivity,
                  preciseModeEnabled: _preciseModeEnabled,
                  jobActivityLevel: _jobActivityLevel,
                  exerciseDaysPerWeek: _exerciseDaysPerWeek,
                  exerciseIntensity: _exerciseIntensity,
                  onModeChanged: (mode) => setState(() => _mode = mode),
                  onIntensityChanged: (intensity) =>
                      setState(() => _intensity = intensity),
                  onCustomCalorieDeltaChanged: (delta) =>
                      setState(() => _customCalorieDelta = delta),
                  onTargetWeightChanged: () => setState(() {}),
                  onPreciseModeEnabledChanged: (enabled) {
                    setState(() => _preciseModeEnabled = enabled);
                    _savePreciseActivity();
                  },
                  onJobActivityLevelChanged: (job) {
                    setState(() => _jobActivityLevel = job);
                    _savePreciseActivity();
                  },
                  onExerciseDaysPerWeekChanged: (days) {
                    setState(() => _exerciseDaysPerWeek = days);
                    _savePreciseActivity();
                  },
                  onExerciseIntensityChanged: (intensity) {
                    setState(() => _exerciseIntensity = intensity);
                    _savePreciseActivity();
                  },
                ),
      bottomNavigationBar: profile == null || profile.sex == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save goal'),
              ),
            ),
    );
  }
}

class _MissingSexPrompt extends StatelessWidget {
  final UserProfile profile;

  const _MissingSexPrompt({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'One more thing',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'The BMR formula needs biological sex to calculate accurately.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      context.read<ProfileRepository>().updateSex(Sex.male),
                  child: const Text('Male'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      context.read<ProfileRepository>().updateSex(Sex.female),
                  child: const Text('Female'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Everything below the "Estimated BMR"/goal math funnels toward one
/// number: today's target-calorie range. That's the hero at the top (with
/// a progress bar against what's actually been logged), then how much of
/// it is left to eat, then "Goal" and "Target weight" as the two inputs
/// that shape the hero number, and finally the biology/activity
/// explanation (plus the advanced precision questionnaire) tucked into a
/// collapsed "How we calculated this" section at the bottom — reference
/// material, not something to wade through to change your goal.
class _GoalsBody extends StatelessWidget {
  final UserProfile profile;
  final GoalMode mode;
  final GoalIntensity intensity;
  final double? customCalorieDelta;
  final TextEditingController targetWeightController;
  final UnitSystem unitSystem;
  final ValueChanged<GoalMode> onModeChanged;
  final ValueChanged<GoalIntensity> onIntensityChanged;
  final ValueChanged<double?> onCustomCalorieDeltaChanged;
  final VoidCallback onTargetWeightChanged;
  final HealthActivitySummary? healthActivity;
  final bool preciseModeEnabled;
  final JobActivityLevel? jobActivityLevel;
  final int? exerciseDaysPerWeek;
  final ExerciseIntensity? exerciseIntensity;
  final ValueChanged<bool> onPreciseModeEnabledChanged;
  final ValueChanged<JobActivityLevel> onJobActivityLevelChanged;
  final ValueChanged<int> onExerciseDaysPerWeekChanged;
  final ValueChanged<ExerciseIntensity> onExerciseIntensityChanged;

  const _GoalsBody({
    required this.profile,
    required this.mode,
    required this.intensity,
    required this.customCalorieDelta,
    required this.targetWeightController,
    required this.unitSystem,
    required this.onModeChanged,
    required this.onIntensityChanged,
    required this.onCustomCalorieDeltaChanged,
    required this.onTargetWeightChanged,
    this.healthActivity,
    required this.preciseModeEnabled,
    required this.jobActivityLevel,
    required this.exerciseDaysPerWeek,
    required this.exerciseIntensity,
    required this.onPreciseModeEnabledChanged,
    required this.onJobActivityLevelChanged,
    required this.onExerciseDaysPerWeekChanged,
    required this.onExerciseIntensityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final training = context.watch<TrainingRepository>();
    final settings = context.watch<SettingsRepository>();
    final cycle = context.watch<CycleRepository>();
    final nutrition = context.watch<NutritionRepository>();
    final todayCalories = nutrition.totalsForDate(DateTime.now()).calories;
    final scheme = Theme.of(context).colorScheme;

    final cyclePhase = settings.cycleTrackingEnabled
        ? currentPhase(cycle.entries.map((e) => e.date).toList())
        : null;
    final cycleAdjustmentKcal = settings.cycleAdjustCalories
        ? lutealCalorieAdjustment(cyclePhase)
        : null;

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final sessionsLast7Days =
        training.sessions.where((s) => s.date.isAfter(weekAgo)).length;

    final currentWeight = training.latestWeightKg ?? profile.weightKg;

    final activity = healthActivity;
    final healthOverrideActivity = activity == null
        ? null
        : BmrCalculator.activityFromHealthData(
            avgSteps: activity.avgSteps,
            avgActiveEnergyKcal: activity.avgActiveEnergyKcal,
          );

    final resolved = resolveActivitySources(
      profile: profile,
      sessionsLast7Days: sessionsLast7Days,
      overrideActivity: healthOverrideActivity,
    );

    final result = BmrCalculator.calculate(
      sex: profile.sex!,
      weightKg: currentWeight,
      heightCm: profile.heightCm,
      age: profile.age,
      sessionsLast7Days: sessionsLast7Days,
      overrideActivity: resolved.overrideActivity,
      avgActiveEnergyKcal: activity?.avgActiveEnergyKcal,
      preciseActivity: resolved.preciseActivity,
    );

    final goal = NutritionGoal(
      mode: mode,
      intensity: intensity,
      customCalorieDelta: customCalorieDelta,
      updatedAt: DateTime.now(),
    );

    final target = computeTargetCalories(
      profile: profile,
      goal: goal,
      currentWeightKg: currentWeight,
      sessions: training.sessions,
      overrideActivity: healthOverrideActivity,
      avgActiveEnergyKcal: activity?.avgActiveEnergyKcal,
      cyclePhaseAdjustmentKcal: cycleAdjustmentKcal,
    )!;

    final targetWeightKg = targetWeightController.text.trim().isEmpty
        ? null
        : Units.parseWeightToKg(targetWeightController.text.trim(), unitSystem);

    // Same goal (deficit/surplus/maintain), same math, just with the
    // target weight substituted in — so this reflects what you'd actually
    // eat once you get there, not a bare maintenance-only estimate.
    final targetAtGoalWeight = targetWeightKg == null
        ? null
        : computeTargetCalories(
            profile: profile,
            goal: goal,
            currentWeightKg: targetWeightKg,
            sessions: training.sessions,
            overrideActivity: healthOverrideActivity,
            avgActiveEnergyKcal: activity?.avgActiveEnergyKcal,
            cyclePhaseAdjustmentKcal: cycleAdjustmentKcal,
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _TodayTargetCard(
          mode: mode,
          target: target,
          todayCalories: todayCalories,
          cycleAdjustmentKcal: cycleAdjustmentKcal,
        ),
        const SizedBox(height: 16),
        _LoggedIntakeCard(target: target, todayCalories: todayCalories),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Goal', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                CalorieDeltaEditor(
                  mode: mode,
                  intensity: intensity,
                  customCalorieDelta: customCalorieDelta,
                  onModeChanged: onModeChanged,
                  onIntensityChanged: onIntensityChanged,
                  onCustomCalorieDeltaChanged: onCustomCalorieDeltaChanged,
                ),
                const Divider(height: 32),
                Text('Target weight', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Optional — set one to see progress and what you\'d eat once you get there.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Target weight (${Units.weightUnitLabel(unitSystem)})',
                  ),
                  onChanged: (_) => onTargetWeightChanged(),
                ),
                if (targetWeightKg != null) ...[
                  const SizedBox(height: 16),
                  _WeightProgress(
                    currentWeightKg: currentWeight,
                    targetWeightKg: targetWeightKg,
                    unitSystem: unitSystem,
                  ),
                  if (targetAtGoalWeight != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'At that weight',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCalorieRange(targetAtGoalWeight.low, targetAtGoalWeight.high),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      mode == GoalMode.maintain
                          ? 'To maintain it'
                          : 'Same ${mode.label.toLowerCase()}, at your target weight',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _CalculationDetails(
          bmr: result.bmr,
          activityLabel: _activitySourceLabel(
            activityLabel: result.activity.label,
            hasHealthData: activity != null,
            hasPreciseActivity: resolved.preciseActivity != null,
            hasInitialActivityFallback: resolved.overrideActivity != null && activity == null,
            sessionsLast7Days: sessionsLast7Days,
          ),
          tdeeLow: result.tdeeLow,
          tdeeHigh: result.tdeeHigh,
          preciseModeEnabled: preciseModeEnabled,
          jobActivityLevel: jobActivityLevel,
          exerciseDaysPerWeek: exerciseDaysPerWeek,
          exerciseIntensity: exerciseIntensity,
          onPreciseModeEnabledChanged: onPreciseModeEnabledChanged,
          onJobActivityLevelChanged: onJobActivityLevelChanged,
          onExerciseDaysPerWeekChanged: onExerciseDaysPerWeekChanged,
          onExerciseIntensityChanged: onExerciseIntensityChanged,
        ),
      ],
    );
  }
}

/// The hero number — what to actually eat today, front and center instead
/// of buried under the biology that produced it. Reflects [mode] directly:
/// by default this is plain maintenance, but a deficit/surplus goal shifts
/// the number (and the chip) accordingly — same `target` this whole screen
/// (and the rest of the app) computes from, so it can never drift out of
/// sync with what "Deficit"/"Surplus" actually mean elsewhere.
class _TodayTargetCard extends StatelessWidget {
  final GoalMode mode;
  final TargetCalories target;
  final double todayCalories;
  final int? cycleAdjustmentKcal;

  const _TodayTargetCard({
    required this.mode,
    required this.target,
    required this.todayCalories,
    this.cycleAdjustmentKcal,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reference = (target.low + target.high) / 2;
    final fraction = reference <= 0 ? 0.0 : (todayCalories / reference).clamp(0.0, 1.0);

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Today's target",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                  ),
                ),
                if (mode != GoalMode.maintain)
                  Chip(
                    label: Text(mode.label),
                    labelStyle: TextStyle(color: scheme.onPrimary),
                    backgroundColor: scheme.primary,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide.none,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatCalorieRange(target.low, target.high),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (cycleAdjustmentKcal != null) ...[
              const SizedBox(height: 4),
              Text(
                '+$cycleAdjustmentKcal kcal · luteal phase',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: scheme.onPrimaryContainer.withValues(alpha: 0.15),
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${todayCalories.round()} of ${reference.round()} kcal logged',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What's actually been logged today, and what's left against the target
/// above — a precise readout to sit next to that card's progress bar, since
/// a bar communicates "roughly how full" but not the exact numbers.
class _LoggedIntakeCard extends StatelessWidget {
  final TargetCalories target;
  final double todayCalories;

  const _LoggedIntakeCard({required this.target, required this.todayCalories});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reference = (target.low + target.high) / 2;
    final remaining = reference - todayCalories;

    return Card(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's intake",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onTertiaryContainer,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${todayCalories.round()} kcal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  remaining >= 0 ? 'Remaining' : 'Over',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onTertiaryContainer,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${remaining.abs().round()} kcal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightProgress extends StatelessWidget {
  final double currentWeightKg;
  final double? targetWeightKg;
  final UnitSystem unitSystem;

  const _WeightProgress({
    required this.currentWeightKg,
    required this.unitSystem,
    this.targetWeightKg,
  });

  @override
  Widget build(BuildContext context) {
    final target = targetWeightKg;
    if (target == null) return const SizedBox.shrink();

    final delta = target - currentWeightKg;
    final scheme = Theme.of(context).colorScheme;
    final deltaText = Units.formatWeight(delta.abs(), unitSystem);

    final message = delta.abs() < 0.1
        ? "You're at your target weight"
        : delta < 0
            ? '$deltaText to lose'
            : '$deltaText to gain';

    return Row(
      children: [
        Icon(
          delta < 0 ? Icons.trending_down : Icons.trending_up,
          color: scheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

String _activitySourceLabel({
  required String activityLabel,
  required bool hasHealthData,
  required bool hasPreciseActivity,
  required bool hasInitialActivityFallback,
  required int sessionsLast7Days,
}) {
  if (hasHealthData) return '$activityLabel · from your measured activity';
  if (hasPreciseActivity) return '$activityLabel · from your job & exercise answers';
  if (hasInitialActivityFallback) return '$activityLabel · your reported activity level';
  final workoutWord = sessionsLast7Days == 1 ? 'workout' : 'workouts';
  return '$activityLabel · $sessionsLast7Days $workoutWord in the last 7 days';
}

/// Reference material collapsed by default: the raw BMR/TDEE numbers behind
/// today's target, plus the opt-in "Precise calorie tracking" questionnaire
/// — kept out of the main Goal/Target-weight flow so turning it on doesn't
/// visually take over the screen. Starts expanded once the user has
/// actually turned precision on, since at that point it's no longer purely
/// background reading.
class _CalculationDetails extends StatelessWidget {
  final double bmr;
  final String activityLabel;
  final double tdeeLow;
  final double tdeeHigh;
  final bool preciseModeEnabled;
  final JobActivityLevel? jobActivityLevel;
  final int? exerciseDaysPerWeek;
  final ExerciseIntensity? exerciseIntensity;
  final ValueChanged<bool> onPreciseModeEnabledChanged;
  final ValueChanged<JobActivityLevel> onJobActivityLevelChanged;
  final ValueChanged<int> onExerciseDaysPerWeekChanged;
  final ValueChanged<ExerciseIntensity> onExerciseIntensityChanged;

  const _CalculationDetails({
    required this.bmr,
    required this.activityLabel,
    required this.tdeeLow,
    required this.tdeeHigh,
    required this.preciseModeEnabled,
    required this.jobActivityLevel,
    required this.exerciseDaysPerWeek,
    required this.exerciseIntensity,
    required this.onPreciseModeEnabledChanged,
    required this.onJobActivityLevelChanged,
    required this.onExerciseDaysPerWeekChanged,
    required this.onExerciseIntensityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: preciseModeEnabled,
          title: Text('How we calculated this', style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(
            '${bmr.round()} kcal BMR · $activityLabel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Estimated maintenance', style: Theme.of(context).textTheme.labelLarge),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                formatCalorieRange(tdeeLow, tdeeHigh),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                (tdeeHigh - tdeeLow).abs() < 0.5
                    ? "Picked from your job & exercise answers, not a ballpark range."
                    : "A ballpark — like the calculators online, not a lab measurement.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
            const Divider(height: 28),
            _PreciseActivitySection(
              enabled: preciseModeEnabled,
              job: jobActivityLevel,
              exerciseDaysPerWeek: exerciseDaysPerWeek,
              intensity: exerciseIntensity,
              onEnabledChanged: onPreciseModeEnabledChanged,
              onJobChanged: onJobActivityLevelChanged,
              onExerciseDaysPerWeekChanged: onExerciseDaysPerWeekChanged,
              onIntensityChanged: onExerciseIntensityChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opt-in questionnaire that picks one exact tier off the standard 6-level
/// activity table instead of leaving the default +/-150 kcal ballpark range
/// — see [PreciseActivityInput]. Saves immediately on change (like a
/// settings toggle), independent of the "Save goal" button.
class _PreciseActivitySection extends StatelessWidget {
  final bool enabled;
  final JobActivityLevel? job;
  final int? exerciseDaysPerWeek;
  final ExerciseIntensity? intensity;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<JobActivityLevel> onJobChanged;
  final ValueChanged<int> onExerciseDaysPerWeekChanged;
  final ValueChanged<ExerciseIntensity> onIntensityChanged;

  const _PreciseActivitySection({
    required this.enabled,
    required this.job,
    required this.exerciseDaysPerWeek,
    required this.intensity,
    required this.onEnabledChanged,
    required this.onJobChanged,
    required this.onExerciseDaysPerWeekChanged,
    required this.onIntensityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = exerciseDaysPerWeek ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Precise calorie tracking'),
          subtitle: const Text(
            'Answer a couple more questions to replace the range above with one exact number',
          ),
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        if (enabled) ...[
          const SizedBox(height: 8),
          Text('Daily activity', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: JobActivityLevel.values.map((level) {
              return ChoiceChip(
                label: Text(level.label),
                selected: job == level,
                onSelected: (_) => onJobChanged(level),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Exercise days per week', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: days.toDouble(),
                  min: 0,
                  max: 7,
                  divisions: 7,
                  label: '$days',
                  onChanged: (value) => onExerciseDaysPerWeekChanged(value.round()),
                ),
              ),
              SizedBox(
                width: 24,
                child: Text(
                  '$days',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Typical intensity', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ExerciseIntensity.values.map((level) {
              return ChoiceChip(
                label: Text(level.label),
                selected: intensity == level,
                onSelected: (_) => onIntensityChanged(level),
              );
            }).toList(),
          ),
          if (job == null || intensity == null) ...[
            const SizedBox(height: 12),
            Text(
              'Pick a daily activity and intensity to use this instead of guessing from your logged workouts.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ],
    );
  }
}
