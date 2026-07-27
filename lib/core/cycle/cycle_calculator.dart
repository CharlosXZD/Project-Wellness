enum CyclePhase { menstrual, follicular, ovulation, luteal }

DateTime _dateOnly(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);

/// Average gap between consecutive logged period-start dates, clamped to a
/// sane 21-35 day range so one mis-logged date can't wildly skew the phase
/// estimate. Falls back to the textbook 28-day average with fewer than two
/// entries to compare.
int estimatedCycleLength(List<DateTime> periodStarts) {
  if (periodStarts.length < 2) return 28;

  final sorted = periodStarts.map(_dateOnly).toList()..sort();
  var totalDays = 0;
  for (var i = 1; i < sorted.length; i++) {
    totalDays += sorted[i].difference(sorted[i - 1]).inDays;
  }
  final average = totalDays / (sorted.length - 1);
  return average.round().clamp(21, 35);
}

/// Maps a single 0-indexed day within a cycle of [cycleLength] to its phase
/// — the shared boundary rules used both by [currentPhase] (for today) and
/// by `CyclePhaseWheel` (to color every day around the ring consistently).
CyclePhase phaseForDayInCycle(int dayInCycle, int cycleLength) {
  const menstrualEnd = 4; // days 1-5
  final ovulationStart = (cycleLength / 2).floor() - 1;
  final ovulationEnd = (cycleLength / 2).floor() + 1;

  if (dayInCycle <= menstrualEnd) return CyclePhase.menstrual;
  if (dayInCycle < ovulationStart) return CyclePhase.follicular;
  if (dayInCycle <= ovulationEnd) return CyclePhase.ovulation;
  return CyclePhase.luteal;
}

/// Estimates today's cycle phase from logged period-start dates, using
/// [estimatedCycleLength] (or the user's own history once there's enough of
/// it) to place today within the most recent cycle. Returns `null` when
/// nothing has been logged yet — there's nothing to estimate from.
CyclePhase? currentPhase(List<DateTime> periodStarts, {DateTime? now}) {
  if (periodStarts.isEmpty) return null;

  final today = _dateOnly(now ?? DateTime.now());
  final lastStart = periodStarts.map(_dateOnly).reduce(
        (a, b) => a.isAfter(b) ? a : b,
      );
  final cycleLength = estimatedCycleLength(periodStarts);
  final daysSince = today.difference(lastStart).inDays;
  final dayInCycle = (daysSince < 0 ? 0 : daysSince) % cycleLength;

  return phaseForDayInCycle(dayInCycle, cycleLength);
}

/// Which day (0-indexed within the cycle) today falls on, alongside the
/// estimated cycle length — the pair `CyclePhaseWheel` needs to know both
/// how many days to draw around the ring and where to put the marker.
/// Returns `null` when nothing has been logged yet.
({int dayInCycle, int cycleLength})? currentCyclePosition(
  List<DateTime> periodStarts, {
  DateTime? now,
}) {
  if (periodStarts.isEmpty) return null;

  final today = _dateOnly(now ?? DateTime.now());
  final lastStart = periodStarts.map(_dateOnly).reduce(
        (a, b) => a.isAfter(b) ? a : b,
      );
  final cycleLength = estimatedCycleLength(periodStarts);
  final daysSince = today.difference(lastStart).inDays;
  final dayInCycle = (daysSince < 0 ? 0 : daysSince) % cycleLength;

  return (dayInCycle: dayInCycle, cycleLength: cycleLength);
}

/// A small, fixed, clearly-labeled estimate — not computed per-user — since
/// the luteal-phase BMR bump is real but too individually variable to claim
/// more precision than a flat, honest nudge.
int? lutealCalorieAdjustment(CyclePhase? phase) {
  return phase == CyclePhase.luteal ? 100 : null;
}
