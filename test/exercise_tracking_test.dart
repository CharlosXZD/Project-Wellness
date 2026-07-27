import 'package:flutter_test/flutter_test.dart';
import 'package:project_wellness/models/exercise_def.dart';
import 'package:project_wellness/repositories/active_workout_repository.dart';

void main() {
  group('isDurationBasedTracking', () {
    test('falls back to category when trackingType is null', () {
      expect(isDurationBasedTracking(category: 'Cardio', trackingType: null), isTrue);
      expect(isDurationBasedTracking(category: 'Pilates', trackingType: null), isTrue);
      expect(isDurationBasedTracking(category: 'Chest', trackingType: null), isFalse);
    });

    test('an explicit trackingType overrides category in both directions', () {
      expect(
        isDurationBasedTracking(category: 'Chest', trackingType: ExerciseTrackingType.timed),
        isTrue,
      );
      expect(
        isDurationBasedTracking(category: 'Chest', trackingType: ExerciseTrackingType.distance),
        isTrue,
      );
      expect(
        isDurationBasedTracking(category: 'Cardio', trackingType: ExerciseTrackingType.standard),
        isFalse,
      );
    });
  });

  group('isDistanceTracking', () {
    test('falls back to category when trackingType is null', () {
      expect(isDistanceTracking(category: 'Cardio', trackingType: null), isTrue);
      expect(isDistanceTracking(category: 'Pilates', trackingType: null), isFalse);
    });

    test('an explicit trackingType overrides category in both directions', () {
      expect(
        isDistanceTracking(category: 'Chest', trackingType: ExerciseTrackingType.distance),
        isTrue,
      );
      expect(
        isDistanceTracking(category: 'Chest', trackingType: ExerciseTrackingType.timed),
        isFalse,
      );
      expect(
        isDistanceTracking(category: 'Cardio', trackingType: ExerciseTrackingType.timed),
        isFalse,
      );
    });
  });
}
