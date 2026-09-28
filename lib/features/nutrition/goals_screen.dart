import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/nutrition/bmr_calculator.dart';
import '../../core/nutrition/daily_target_scope.dart';
import '../../core/nutrition/target_calories.dart';
import '../../core/units/units.dart';
import '../../models/nutrition_goal.dart';
import '../../models/user_profile.dart';
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

  @override
  void initState() {
    super.initState();
    final goal = context.read<NutritionRepository>().goal;
    final unitSystem = context.read<SettingsRepository>().unitSystem;
    _mode = goal?.mode ?? GoalMode.maintain;
    _intensity = goal?.intensity ?? GoalIntensity.moderate;
    _customCalorieDelta = goal?.customCalorieDelta;
    _targetWeightController = TextEditingController(
      text: goal?.targetWeightKg == null
          ? ''
          : Units.formatNumber(
              unitSystem == UnitSystem.metric ? goal!.targetWeightKg! : Units.kgToLbs(goal!.targetWeightKg!),
            ),
    );
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final unitSystem = context.read<SettingsRepository>().unitSystem;
    final targetWeight = Units.parseWeightToKg(_targetWeightController.text.trim(), unitSystem);
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
                  goal: NutritionGoal(
                    mode: _mode,
                    intensity: _intensity,
                    customCalorieDelta: _customCalorieDelta,
                    updatedAt: DateTime.now(),
                  ),
                  targetWeightController: _targetWeightController,
                  unitSystem: unitSystem,
                  onModeChanged: (mode) => setState(() => _mode = mode),
                  onIntensityChanged: (intensity) => setState(() => _intensity = intensity),
                  onCustomCalorieDeltaChanged: (delta) => setState(() => _customCalorieDelta = delta),
                  onTargetWeightChanged: () => setState(() {}),
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
                  onPressed: () => context.read<ProfileRepository>().updateSex(Sex.male),
                  child: const Text('Male'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.read<ProfileRepository>().updateSex(Sex.female),
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

/// Everything funnels toward one number: today's calorie target. That's
/// the hero at the top (with the maintenance − deficit arithmetic spelled
/// out), then the two inputs that shape it (goal, target weight), then the
/// full calculation — BMR, the formula estimate, what the user's own logs
/// measured, and the activity questions — in a section below.
class _GoalsBody extends StatelessWidget {
  final UserProfile profile;
  final NutritionGoal goal;
  final TextEditingController targetWeightController;
  final UnitSystem unitSystem;
  final ValueChanged<GoalMode> onModeChanged;
  final ValueChanged<GoalIntensity> onIntensityChanged;
  final ValueChanged<double?> onCustomCalorieDeltaChanged;
  final VoidCallback onTargetWeightChanged;

  const _GoalsBody({
    required this.profile,
    required this.goal,
    required this.targetWeightController,
    required this.unitSystem,
    required this.onModeChanged,
    required this.onIntensityChanged,
    required this.onCustomCalorieDeltaChanged,
    required this.onTargetWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    final nutrition = context.watch<NutritionRepository>();
    final todayCalories = nutrition.totalsForDate(DateTime.now()).calories;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final target = watchDailyTarget(context, goal: goal)!;
    final targetWeightKg = targetWeightController.text.trim().isEmpty
        ? null
        : Units.parseWeightToKg(targetWeightController.text.trim(), unitSystem);
    final atTargetWeight = targetWeightKg == null || targetWeightKg <= 0
        ? null
        : watchDailyTarget(context, goal: goal, weightKg: targetWeightKg);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _TodayTargetCard(target: target, todayCalories: todayCalories),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Goal', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                CalorieDeltaEditor(
                  mode: goal.mode,
                  intensity: goal.intensity,
                  customCalorieDelta: goal.customCalorieDelta,
                  onModeChanged: onModeChanged,
                  onIntensityChanged: onIntensityChanged,
                  onCustomCalorieDeltaChanged: onCustomCalorieDeltaChanged,
                ),
                if (goal.mode != GoalMode.maintain) ...[
                  const SizedBox(height: 8),
                  Text(
                    '≈ ${Units.formatWeight(goal.effectiveCalorieDelta * 7 / kcalPerKgBodyWeight, unitSystem)} per week',
                    style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                const Divider(height: 32),
                Text('Target weight', style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Optional — set one to see progress and what you\'d eat once you get there.',
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Target weight',
                    suffixText: Units.weightUnitLabel(unitSystem),
                  ),
                  onChanged: (_) => onTargetWeightChanged(),
                ),
                if (targetWeightKg != null && atTargetWeight != null) ...[
                  const SizedBox(height: 16),
                  _WeightProgress(
                    currentWeightKg: target.weightKg,
                    targetWeightKg: targetWeightKg,
                    weeklyChangeKg: goal.mode == GoalMode.maintain
                        ? null
                        : goal.effectiveCalorieDelta * 7 / kcalPerKgBodyWeight,
                    unitSystem: unitSystem,
                  ),
                  const SizedBox(height: 12),
                  Text('At that weight', style: textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(formatKcal(atTargetWeight.kcal), style: textTheme.titleLarge),
                  Text(
                    goal.mode == GoalMode.maintain
                        ? 'To maintain it'
                        : 'Same ${goal.mode.label.toLowerCase()}, at your target weight · '
                            '${formatKcal(atTargetWeight.maintenanceKcal)} to maintain',
                    style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('How we calculated this', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        _CalculationCard(profile: profile, target: target, unitSystem: unitSystem),
        const SizedBox(height: 16),
        _ActivitySection(profile: profile),
      ],
    );
  }
}

/// The hero number, with the arithmetic that produced it right underneath.
class _TodayTargetCard extends StatelessWidget {
  final DailyTarget target;
  final double todayCalories;

  const _TodayTargetCard({required this.target, required this.todayCalories});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fraction = target.kcal <= 0 ? 0.0 : (todayCalories / target.kcal).clamp(0.0, 1.0);
    final remaining = target.kcal - todayCalories;
    final onColor = scheme.onPrimaryContainer;

    final parts = <String>[
      '${target.maintenanceKcal.round()} maintenance',
      if (target.goalAdjustmentKcal != 0)
        '${target.goalAdjustmentKcal < 0 ? '−' : '+'} ${target.goalAdjustmentKcal.abs().round()} ${target.mode.label.toLowerCase()}',
      if (target.cycleAdjustmentKcal != null) '+ ${target.cycleAdjustmentKcal} luteal phase',
    ];

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
                  child: Text("Today's target", style: textTheme.titleMedium?.copyWith(color: onColor)),
                ),
                if (target.mode != GoalMode.maintain)
                  Chip(
                    label: Text(target.mode.label),
                    labelStyle: TextStyle(color: scheme.onPrimary),
                    backgroundColor: scheme.primary,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide.none,
                  ),
              ],
            ),
            Text(
              formatKcal(target.kcal),
              style: textTheme.displaySmall?.copyWith(color: onColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(parts.join(' '), style: textTheme.bodySmall?.copyWith(color: onColor)),
            if (target.raisedToMinimum) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: onColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Raised to the ${target.kcal.round()} kcal safe minimum — '
                      'pick a gentler goal to lose weight sustainably.',
                      style: textTheme.bodySmall?.copyWith(color: onColor),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: onColor.withValues(alpha: 0.15),
                color: onColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${todayCalories.round()} eaten · ${remaining.abs().round()} kcal ${remaining >= 0 ? 'left' : 'over'}',
              style: textTheme.bodySmall?.copyWith(color: onColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightProgress extends StatelessWidget {
  final double currentWeightKg;
  final double targetWeightKg;
  final double? weeklyChangeKg;
  final UnitSystem unitSystem;

  const _WeightProgress({
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.weeklyChangeKg,
    required this.unitSystem,
  });

  @override
  Widget build(BuildContext context) {
    final delta = targetWeightKg - currentWeightKg;
    final scheme = Theme.of(context).colorScheme;
    final deltaText = Units.formatWeight(delta.abs(), unitSystem);
    final weekly = weeklyChangeKg;
    final weeks = weekly == null || weekly <= 0 ? null : (delta.abs() / weekly).ceil();

    final message = delta.abs() < 0.1
        ? "You're at your target weight"
        : '${delta < 0 ? '$deltaText to lose' : '$deltaText to gain'}'
            '${weeks != null ? ' · about $weeks ${weeks == 1 ? 'week' : 'weeks'} at this pace' : ''}';

    return Row(
      children: [
        Icon(delta < 0 ? Icons.trending_down : Icons.trending_up, color: scheme.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

/// BMR → formula estimate → measured-from-logs → blended maintenance, one
/// row each, plus the "learn from my logs" switch.
class _CalculationCard extends StatelessWidget {
  final UserProfile profile;
  final DailyTarget target;
  final UnitSystem unitSystem;

  const _CalculationCard({required this.profile, required this.target, required this.unitSystem});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final measured = target.measured;
    final formula = target.formula;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CalcRow(
              title: 'Resting burn (BMR)',
              value: formatKcal(formula.bmr),
              detail: 'Mifflin-St Jeor · ${Units.formatWeight(target.weightKg, unitSystem)}, '
                  '${profile.heightCm.round()} cm, ${profile.age} y',
            ),
            _CalcRow(
              title: 'Formula estimate',
              value: formatKcal(formula.tdee),
              detail: '${formula.source.label} · ${formula.detail}',
            ),
            _CalcRow(
              title: 'Measured from your logs',
              value: measured == null ? '—' : formatKcal(measured.tdee),
              detail: measured == null
                  ? target.measuredStatus.missing ?? ''
                  : '${measured.avgIntakeKcal.round()} kcal/day eaten over ${measured.loggedDays} days, '
                      'weight ${measured.weightChangeKgPerWeek <= 0 ? '−' : '+'}'
                      '${Units.formatWeight(measured.weightChangeKgPerWeek.abs(), unitSystem, decimals: 2)}/week',
            ),
            const Divider(indent: 16, endIndent: 16),
            _CalcRow(
              title: 'Your maintenance',
              value: formatKcal(target.maintenanceKcal),
              detail: target.usesMeasured
                  ? '${(target.measuredWeight * 100).round()}% your logs, '
                      '${((1 - target.measuredWeight) * 100).round()}% formula — trusted more as you log more'
                  : 'Formula only',
              emphasize: true,
            ),
            SwitchListTile(
              title: const Text('Learn from my logs'),
              subtitle: const Text(
                'Adjust to your real metabolism using what you eat and how your weight moves',
              ),
              value: profile.useMeasuredTdee,
              onChanged: (value) => context
                  .read<ProfileRepository>()
                  .saveProfile(profile.copyWith(useMeasuredTdee: value)),
            ),
            if (measured == null && profile.useMeasuredTdee)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Needs 2+ weeks of food logs and 3+ weigh-ins to kick in.',
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalcRow extends StatelessWidget {
  final String title;
  final String value;
  final String detail;
  final bool emphasize;

  const _CalcRow({required this.title, required this.value, required this.detail, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: emphasize ? textTheme.titleSmall : textTheme.bodyLarge)),
              Text(value, style: emphasize ? textTheme.titleMedium : textTheme.titleSmall),
            ],
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(detail, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// The activity questions behind the formula estimate. Saves immediately on
/// change, like a settings toggle — these describe the person, not the goal.
class _ActivitySection extends StatelessWidget {
  final UserProfile profile;

  const _ActivitySection({required this.profile});

  void _save(BuildContext context, UserProfile updated) =>
      context.read<ProfileRepository>().saveProfile(updated);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sessions = context.watch<TrainingRepository>().sessions;
    final fourWeeksAgo = DateTime.now().subtract(const Duration(days: 28));
    final recent = sessions.where((s) => s.date.isAfter(fourWeeksAgo)).toList();
    final loggedMinutes = typicalLoggedSessionMinutes(recent);
    final loggedPerWeek = recent.length / 4;

    final enabled = profile.preciseCalorieTrackingEnabled;
    final days = profile.exerciseDaysPerWeek ?? 0;
    final minutes = profile.exerciseMinutesPerSession ?? PreciseActivityInput.defaultMinutesPerSession;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use my activity answers'),
              subtitle: Text(
                enabled
                    ? 'Instead of estimating from the workouts you log here'
                    : 'Off — estimating from your logged workouts '
                        '(${loggedPerWeek.toStringAsFixed(1)}/week, ~$loggedMinutes min)',
              ),
              value: enabled,
              onChanged: (value) => _save(context, profile.copyWith(preciseCalorieTrackingEnabled: value)),
            ),
            if (enabled) ...[
              const SizedBox(height: 8),
              Text('Daily activity outside workouts', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: JobActivityLevel.values.map((level) {
                  return ChoiceChip(
                    label: Text(level.label),
                    selected: profile.jobActivityLevel == level,
                    onSelected: (_) => _save(context, profile.copyWith(jobActivityLevel: level)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _SliderRow(
                label: 'Workouts per week',
                format: (v) => '$v',
                value: days,
                min: 0,
                max: 7,
                divisions: 7,
                onChanged: (v) => _save(context, profile.copyWith(exerciseDaysPerWeek: v)),
              ),
              _SliderRow(
                label: 'Typical workout length',
                format: (v) => '$v min',
                value: minutes,
                min: 15,
                max: 180,
                divisions: 11,
                onChanged: (v) => _save(context, profile.copyWith(exerciseMinutesPerSession: v)),
              ),
              if (recent.isNotEmpty)
                Text(
                  'Your logged workouts: ${loggedPerWeek.toStringAsFixed(1)}/week, ~$loggedMinutes min each',
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              const SizedBox(height: 16),
              Text('Typical intensity', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ExerciseIntensity.values.map((level) {
                  return ChoiceChip(
                    label: Text(level.label),
                    selected: profile.exerciseIntensity == level,
                    onSelected: (_) => _save(context, profile.copyWith(exerciseIntensity: level)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Text(
                'Light: easy circuits, walking · Moderate: normal lifting session · Hard: heavy lifting, running, sports',
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (profile.jobActivityLevel == null || profile.exerciseIntensity == null) ...[
                const SizedBox(height: 12),
                Text(
                  'Pick a daily activity and intensity to use these answers.',
                  style: textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Slider that tracks the drag locally and only reports the final value —
/// every report is a database write.
class _SliderRow extends StatefulWidget {
  final String label;
  final String Function(int value) format;
  final int value;
  final int min;
  final int max;
  final int divisions;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    required this.label,
    required this.format,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  State<_SliderRow> createState() => _SliderRowState();
}

class _SliderRowState extends State<_SliderRow> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final value = (_dragValue ?? widget.value.toDouble()).clamp(widget.min.toDouble(), widget.max.toDouble());
    final label = widget.format(value.round());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.label, style: Theme.of(context).textTheme.labelLarge)),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        Slider(
          value: value,
          min: widget.min.toDouble(),
          max: widget.max.toDouble(),
          divisions: widget.divisions,
          label: label,
          onChanged: (v) => setState(() => _dragValue = v),
          onChangeEnd: (v) {
            widget.onChanged(v.round());
            setState(() => _dragValue = null);
          },
        ),
      ],
    );
  }
}
