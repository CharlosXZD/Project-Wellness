import 'package:flutter_test/flutter_test.dart';
import 'package:project_wellness/core/sharing/library_share.dart';

void main() {
  group('newItemsByName', () {
    test('keeps items not already present by name', () {
      final result = newItemsByName<String>(
        incoming: ['Plank', 'Farmer Carry'],
        existingNames: ['Push-Up'],
        nameOf: (s) => s,
      );
      expect(result, ['Plank', 'Farmer Carry']);
    });

    test('skips items already present, case-insensitive and trimmed', () {
      final result = newItemsByName<String>(
        incoming: [' plank ', 'Farmer Carry'],
        existingNames: ['Plank'],
        nameOf: (s) => s,
      );
      expect(result, ['Farmer Carry']);
    });

    test('skips duplicates within incoming itself', () {
      final result = newItemsByName<String>(
        incoming: ['Plank', 'PLANK', 'Farmer Carry'],
        existingNames: const [],
        nameOf: (s) => s,
      );
      expect(result, ['Plank', 'Farmer Carry']);
    });

    test('returns an empty list when everything already exists', () {
      final result = newItemsByName<String>(
        incoming: ['Plank'],
        existingNames: ['Plank'],
        nameOf: (s) => s,
      );
      expect(result, isEmpty);
    });
  });
}
