import 'package:flutter_test/flutter_test.dart';
import 'package:project_wellness/core/nutrition/bmr_calculator.dart';
import 'package:project_wellness/core/nutrition/target_calories.dart';
import 'package:project_wellness/models/user_profile.dart';
import 'package:project_wellness/models/workout_session.dart';

UserProfile _profile({
  DateTime? createdAt,
  SelfReportedActivityLevel? initialActivityLevel,
  bool preciseCalorieTrackingEnabled = false,
  JobActivityLevel? jobActivityLevel,
  int? exerciseDaysPerWeek,
  ExerciseIntensity? exerciseIntensity,
}) {
  return UserProfile(
    name: 'Test',
    dateOfBirth: DateTime(1995, 1, 1),
    heightCm: 178,
    weightKg: 75,
    sex: Sex.male,
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(days: 60)),
    initialActivityLevel: initialActivityLevel,
    preciseCalorieTrackingEnabled: preciseCalorieTrackingEnabled,
    jobActivityLevel: jobActivityLevel,
    exerciseDaysPerWeek: exerciseDaysPerWeek,
    exerciseIntensity: exerciseIntensity,
  );
}

void main() {
  group('computeTargetCalories activity source priority', () {
    test('falls back to the flat +/-150 session-count heuristic by default', () {
      final target = computeTargetCalories(
        profile: _profile(),
        goal: null,
        currentWeightKg: 75,
        sessions: const [],
      )!;

      expect(target.high - target.low, 300);
    });

    test('uses the onboarding self-report for a brand-new, sparse-history account', () {
      final newProfile = _profile(
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        initialActivityLevel: SelfReportedActivityLevel.extreme,
      );
      final withReport = computeTargetCalories(
        profile: newProfile,
        goal: null,
        currentWeightKg: 75,
        sessions: const [],
      )!;
      final withoutReport = computeTargetCalories(
        profile: _profile(createdAt: DateTime.now().subtract(const Duration(days: 2))),
        goal: null,
        currentWeightKg: 75,
        sessions: const [],
      )!;

      expect(withReport.low, greaterThan(withoutReport.low));
      expect(withReport.high - withReport.low, 300, reason: 'still the default +/-150 band');
    });

    test('ignores the onboarding self-report once the account has real workout history', () {
      final oldProfile = _profile(
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        initialActivityLevel: SelfReportedActivityLevel.extreme,
      );
      final sessions = List.generate(
        5,
        (i) => WorkoutSession(
          id: 'w$i',
          dayName: 'Day $i',
          name: 'Session $i',
          date: DateTime.now().subtract(Duration(days: i)),
        ),
      );

      final withHistory = computeTargetCalories(
        profile: oldProfile,
        goal: null,
        currentWeightKg: 75,
        sessions: sessions,
      )!;
      final zeroSessionHeuristic = computeTargetCalories(
        profile: _profile(createdAt: DateTime.now().subtract(const Duration(days: 90))),
        goal: null,
        currentWeightKg: 75,
        sessions: const [],
      )!;

      // With 5 sessions logged, the session-count heuristic (not the stale
      // "extreme" self-report) should drive the number, so it should differ
      // from the zero-session sedentary baseline.
      expect(withHistory.low, isNot(zeroSessionHeuristic.low));
    });

    test('precise mode drops the band to an exact number and beats the session heuristic', () {
      final target = computeTargetCalories(
        profile: _profile(
          preciseCalorieTrackingEnabled: true,
          jobActivityLevel: JobActivityLevel.physical,
          exerciseDaysPerWeek: 6,
          exerciseIntensity: ExerciseIntensity.hard,
        ),
        goal: null,
        currentWeightKg: 75,
        sessions: const [],
      )!;

      expect(target.high - target.low, 0);
    });

    test('a real health-data override still beats precise mode', () {
      final withHealth = computeTargetCalories(
        profile: _profile(
          preciseCalorieTrackingEnabled: true,
          jobActivityLevel: JobActivityLevel.desk,
          exerciseDaysPerWeek: 0,
          exerciseIntensity: ExerciseIntensity.light,
        ),
        goal: null,
        currentWeightKg: 75,
        sessions: const [],
        overrideActivity: const ActivityLevel(multiplier: 1.9, label: 'Extremely active'),
      )!;

      // Health override wins -> band stays the default +/-150, not the
      // narrowed +/-75 precise-mode band.
      expect(withHealth.high - withHealth.low, 300);
    });

    test('disabling precise mode falls back even if the answers are still stored', () {
      final target = computeTargetCalories(
        profile: _profile(
          preciseCalorieTrackingEnabled: false,
          jobActivityLevel: JobActivityLevel.physical,
          exerciseDaysPerWeek: 6,
          exerciseIntensity: ExerciseIntensity.hard,
        ),
        goal: null,
        currentWeightKg: 75,
        sessions: const [],
      )!;

      expect(target.high - target.low, 300);
    });
  });
}
