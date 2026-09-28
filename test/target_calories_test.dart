import 'package:flutter_test/flutter_test.dart';
import 'package:project_wellness/core/health/health_service.dart';
import 'package:project_wellness/core/nutrition/bmr_calculator.dart';
import 'package:project_wellness/core/nutrition/intake_stats.dart';
import 'package:project_wellness/core/nutrition/target_calories.dart';
import 'package:project_wellness/models/food_entry.dart';
import 'package:project_wellness/models/nutrition_goal.dart';
import 'package:project_wellness/models/user_profile.dart';
import 'package:project_wellness/models/weight_entry.dart';
import 'package:project_wellness/models/workout_session.dart';
import 'package:project_wellness/repositories/nutrition_repository.dart';

final _now = DateTime(2026, 9, 28, 12);

UserProfile _profile({
  DateTime? createdAt,
  SelfReportedActivityLevel? initialActivityLevel,
  bool preciseCalorieTrackingEnabled = false,
  JobActivityLevel? jobActivityLevel,
  int? exerciseDaysPerWeek,
  ExerciseIntensity? exerciseIntensity,
  int? exerciseMinutesPerSession,
  bool useMeasuredTdee = true,
  Sex sex = Sex.male,
}) {
  return UserProfile(
    name: 'Test',
    dateOfBirth: DateTime(2005, 6, 8),
    heightCm: 180.34,
    weightKg: 106.6,
    sex: sex,
    createdAt: createdAt ?? _now.subtract(const Duration(days: 70)),
    initialActivityLevel: initialActivityLevel,
    preciseCalorieTrackingEnabled: preciseCalorieTrackingEnabled,
    jobActivityLevel: jobActivityLevel,
    exerciseDaysPerWeek: exerciseDaysPerWeek,
    exerciseIntensity: exerciseIntensity,
    exerciseMinutesPerSession: exerciseMinutesPerSession,
    useMeasuredTdee: useMeasuredTdee,
  );
}

WeightEntry _weight(int daysAgo, double kg) =>
    WeightEntry(id: 'w$daysAgo-$kg', date: _now.subtract(Duration(days: daysAgo)), weightKg: kg);

FoodEntry _food(int daysAgo, double kcal) => FoodEntry(
      id: 'f$daysAgo-$kcal',
      date: _now.subtract(Duration(days: daysAgo)),
      mealType: MealType.lunch,
      name: 'Food',
      calories: kcal,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
    );

/// 42 days of [kcal]/day, with weight falling linearly by [kgPerDay] from
/// [startKg], weighed in every 7 days.
({List<FoodEntry> food, List<WeightEntry> weights}) _steadyCut({
  double kcal = 1850,
  double startKg = 101,
  double kgPerDay = 0.13,
  int days = 42,
}) {
  return (
    food: [for (var d = 1; d <= days; d++) _food(d, kcal)],
    weights: [for (var d = days; d >= 0; d -= 7) _weight(d, startKg - (days - d) * kgPerDay)],
  );
}

void main() {
  group('activity answers (formula side)', () {
    test('a desk job + 7 moderate 1-hour workouts no longer maps to the 1.9 "athlete" tier', () {
      final profile = _profile(
        preciseCalorieTrackingEnabled: true,
        jobActivityLevel: JobActivityLevel.desk,
        exerciseDaysPerWeek: 7,
        exerciseIntensity: ExerciseIntensity.moderate,
        exerciseMinutesPerSession: 60,
      );
      final formula = estimateFormulaTdee(profile: profile, weightKg: 95.7, sessions: const [], now: _now);

      // BMR ~1984; the old tier math gave 1984 * 1.9 ≈ 3770.
      expect(formula.bmr, closeTo(1984, 2));
      expect(formula.source, TdeeSource.activityAnswers);
      expect(formula.tdee, closeTo(1984 * 1.2 + 4 * 95.7, 2));
      expect(formula.tdee, lessThan(3000));
    });

    test('longer and harder sessions add more', () {
      PreciseActivityInput input(int minutes, ExerciseIntensity intensity) => PreciseActivityInput(
            job: JobActivityLevel.desk,
            exerciseDaysPerWeek: 5,
            intensity: intensity,
            minutesPerSession: minutes,
          );
      expect(input(90, ExerciseIntensity.moderate).exerciseKcalPerDay(80),
          greaterThan(input(60, ExerciseIntensity.moderate).exerciseKcalPerDay(80)));
      expect(input(60, ExerciseIntensity.hard).exerciseKcalPerDay(80),
          greaterThan(input(60, ExerciseIntensity.moderate).exerciseKcalPerDay(80)));
    });

    test('Health active energy beats the answers when it is meaningful', () {
      final profile = _profile(
        preciseCalorieTrackingEnabled: true,
        jobActivityLevel: JobActivityLevel.desk,
        exerciseDaysPerWeek: 0,
        exerciseIntensity: ExerciseIntensity.light,
      );
      final withHealth = estimateFormulaTdee(
        profile: profile,
        weightKg: 80,
        sessions: const [],
        health: const HealthActivitySummary(avgSteps: 9000, avgActiveEnergyKcal: 600),
        now: _now,
      );
      final phoneOnly = estimateFormulaTdee(
        profile: profile,
        weightKg: 80,
        sessions: const [],
        health: const HealthActivitySummary(avgSteps: 3000, avgActiveEnergyKcal: 40),
        now: _now,
      );
      expect(withHealth.source, TdeeSource.healthData);
      expect(phoneOnly.source, TdeeSource.activityAnswers, reason: 'near-zero active energy is ignored');
    });

    test('a brand-new account uses the onboarding answer', () {
      final formula = estimateFormulaTdee(
        profile: _profile(
          createdAt: _now.subtract(const Duration(days: 2)),
          initialActivityLevel: SelfReportedActivityLevel.active,
        ),
        weightKg: 80,
        sessions: const [],
        now: _now,
      );
      expect(formula.source, TdeeSource.onboardingAnswer);
    });

    test('otherwise estimates from logged workouts, ignoring forgotten timers', () {
      final sessions = [
        for (var i = 0; i < 20; i++)
          WorkoutSession(
            id: 's$i',
            dayName: 'Push',
            name: 'Push',
            date: _now.subtract(Duration(days: i + 1)),
            durationMinutes: i == 0 ? 370 : 75,
          ),
      ];
      expect(typicalLoggedSessionMinutes(sessions), 75);
      final formula = estimateFormulaTdee(profile: _profile(), weightKg: 95, sessions: sessions, now: _now);
      expect(formula.source, TdeeSource.workoutLog);
    });
  });

  group('measured from logs', () {
    test('recovers maintenance from intake + weight trend', () {
      final data = _steadyCut(kcal: 1850, kgPerDay: 0.13);
      final status = measureTdeeFromLogs(foodEntries: data.food, weightEntries: data.weights, now: _now);
      // 1850 + 0.13 * 7700 = 2851
      expect(status.result, isNotNull);
      expect(status.result!.tdee, closeTo(2851, 15));
    });

    test('ignores a typo weigh-in (109 lb typed instead of 209)', () {
      final data = _steadyCut();
      final withTypo = [...data.weights, _weight(0, 49.76)];
      final clean = measureTdeeFromLogs(foodEntries: data.food, weightEntries: data.weights, now: _now);
      final typo = measureTdeeFromLogs(foodEntries: data.food, weightEntries: withTypo, now: _now);
      expect(typo.result!.tdee, closeTo(clean.result!.tdee, 1));
      // The real reading logged the same day as the typo still counts.
      expect(typo.result!.weighIns, clean.result!.weighIns);
    });

    test("ignores today and obviously partial days", () {
      final data = _steadyCut();
      final food = [...data.food, _food(0, 300), _food(10, -1450)]; // day 10 becomes 400 kcal
      final base = measureTdeeFromLogs(foodEntries: data.food, weightEntries: data.weights, now: _now);
      final noisy = measureTdeeFromLogs(foodEntries: food, weightEntries: data.weights, now: _now);
      expect(noisy.result!.avgIntakeKcal, closeTo(base.result!.avgIntakeKcal, 1));
    });

    test('needs enough data before claiming anything', () {
      final data = _steadyCut(days: 10);
      final status = measureTdeeFromLogs(foodEntries: data.food, weightEntries: data.weights, now: _now);
      expect(status.result, isNull);
      expect(status.missing, isNotNull);
    });
  });

  group('computeDailyTarget', () {
    final answers = _profile(
      preciseCalorieTrackingEnabled: true,
      jobActivityLevel: JobActivityLevel.desk,
      exerciseDaysPerWeek: 7,
      exerciseIntensity: ExerciseIntensity.moderate,
    );
    final goal = NutritionGoal(mode: GoalMode.deficit, intensity: GoalIntensity.aggressive, updatedAt: _now);

    test('is one exact number: maintenance minus the goal', () {
      final target = computeDailyTarget(
        profile: _profile(useMeasuredTdee: false, preciseCalorieTrackingEnabled: true,
            jobActivityLevel: JobActivityLevel.desk, exerciseDaysPerWeek: 7,
            exerciseIntensity: ExerciseIntensity.moderate),
        goal: goal,
        weightEntries: [_weight(0, 95.7)],
        sessions: const [],
        foodEntries: const [],
        now: _now,
      )!;
      expect(target.kcal, closeTo(target.maintenanceKcal - 750, 0.01));
      expect(target.usesMeasured, isFalse);
    });

    test('blends in measured maintenance, trusting 6 weeks of data at 90%', () {
      final data = _steadyCut();
      final target = computeDailyTarget(
        profile: answers,
        goal: goal,
        weightEntries: data.weights,
        sessions: const [],
        foodEntries: data.food,
        now: _now,
      )!;
      expect(target.measuredWeight, closeTo(0.9, 0.001));
      expect(
        target.maintenanceKcal,
        closeTo(0.9 * target.measured!.tdee + 0.1 * target.formula.tdee, 0.01),
      );
    });

    test('uses the latest weigh-in, not the stale onboarding weight', () {
      final target = computeDailyTarget(
        profile: answers,
        goal: null,
        weightEntries: [_weight(30, 100), _weight(0, 95.7)],
        sessions: const [],
        foodEntries: const [],
        now: _now,
      )!;
      expect(target.weightKg, 95.7);
    });

    test('never goes below the safe minimum', () {
      final target = computeDailyTarget(
        profile: _profile(sex: Sex.female, useMeasuredTdee: false),
        goal: NutritionGoal(
          mode: GoalMode.deficit,
          intensity: GoalIntensity.aggressive,
          customCalorieDelta: 1500,
          updatedAt: _now,
        ),
        weightEntries: [_weight(0, 55)],
        sessions: const [],
        foodEntries: const [],
        now: _now,
      )!;
      expect(target.kcal, 1200);
      expect(target.raisedToMinimum, isTrue);
    });
  });

  group('IntakeStats', () {
    test('averages completed, logged days only', () {
      final today = DateTime(2026, 9, 28);
      DailyTotal day(int daysAgo, double kcal) => DailyTotal(
            date: today.subtract(Duration(days: daysAgo)),
            totals: MacroTotals(calories: kcal, proteinG: 0, carbsG: 0, fatG: 0),
          );
      final stats = IntakeStats.from(
        [day(3, 2000), day(2, 0), day(1, 1800), day(0, 400)],
        now: DateTime(2026, 9, 28, 9),
      );
      expect(stats.avgCalories, 1900);
      expect(stats.loggedDays, 2);
      expect(stats.completedDays, 3);
    });

    test('chart ranges start at first use', () {
      final firstUse = DateTime(2026, 7, 20);
      expect(chartRangeStart(days: 365, firstUse: firstUse, now: _now), firstUse);
      expect(chartRangeStart(days: 7, firstUse: firstUse, now: _now), DateTime(2026, 9, 22));
    });
  });
}
