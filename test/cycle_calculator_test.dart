import 'package:flutter_test/flutter_test.dart';
import 'package:project_wellness/core/cycle/cycle_calculator.dart';

void main() {
  group('cycle length', () {
    test('defaults to 28 with fewer than two periods', () {
      expect(estimatedCycleLength([DateTime(2026, 9, 1)]), 28);
    });

    test('a missed log (a ~60 day gap) is ignored, not averaged in', () {
      final starts = [
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 31), // 30
        DateTime(2026, 4, 30), // 30
        DateTime(2026, 6, 29), // 60 — one period not logged
        DateTime(2026, 7, 29), // 30
      ];
      expect(estimatedCycleLength(starts), 30);
    });

    test('duplicate or next-day logs of the same period collapse into one', () {
      final starts = [
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 2),
        DateTime(2026, 8, 29),
        DateTime(2026, 8, 29),
      ];
      expect(normalizedPeriodStarts(starts), [DateTime(2026, 8, 1), DateTime(2026, 8, 29)]);
      expect(estimatedCycleLength(starts), 28);
    });
  });

  group('phases', () {
    test('ovulation sits ~14 days before the next period, not at the midpoint', () {
      expect(ovulationDayIndex(28), 13); // day 14
      expect(ovulationDayIndex(35), 20); // day 21 — the old midpoint math said day 18
      expect(phaseForDayInCycle(20, 35), CyclePhase.ovulation);
      expect(phaseForDayInCycle(16, 35), CyclePhase.follicular);
    });

    test('first five days are menstrual, the end is luteal', () {
      expect(phaseForDayInCycle(0, 28), CyclePhase.menstrual);
      expect(phaseForDayInCycle(4, 28), CyclePhase.menstrual);
      expect(phaseForDayInCycle(5, 28), CyclePhase.follicular);
      expect(phaseForDayInCycle(27, 28), CyclePhase.luteal);
    });
  });

  group('current status', () {
    final starts = [DateTime(2026, 8, 1), DateTime(2026, 8, 29)]; // 28-day cycle

    test('predicts the next period and ovulation', () {
      final status = currentCycleStatus(starts, now: DateTime(2026, 9, 10))!;
      expect(status.dayInCycle, 12);
      expect(status.nextPeriodStart, DateTime(2026, 9, 26));
      expect(status.ovulationDate, DateTime(2026, 9, 11));
      expect(status.daysUntilNextPeriod(DateTime(2026, 9, 10)), 16);
      expect(status.isLate, isFalse);
    });

    test('a late period is reported as late instead of wrapping to day 1', () {
      final status = currentCycleStatus(starts, now: DateTime(2026, 9, 29))!;
      expect(status.isLate, isTrue);
      expect(status.daysLate, 4);
      expect(status.phase, CyclePhase.luteal);
    });

    test('a very stale last log gives no estimate', () {
      expect(currentCycleStatus(starts, now: DateTime(2026, 12, 1)), isNull);
    });

    test('period days are shaded from each logged start', () {
      expect(isLoggedPeriodDay(starts, DateTime(2026, 8, 31)), isTrue);
      expect(isLoggedPeriodDay(starts, DateTime(2026, 9, 3)), isFalse);
    });
  });
}
