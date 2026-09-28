enum CyclePhase { menstrual, follicular, ovulation, luteal }

DateTime _dateOnly(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);

/// Default length of the bleed itself, in days — cycle *length* is learned
/// from the user's history, but only the start date is logged, so this
/// stays the textbook figure.
const periodLengthDays = 5;

/// The luteal phase (ovulation to the next period) is the consistent part
/// of a cycle — about 14 days for most people regardless of total cycle
/// length. Cycle-length variation comes almost entirely from the follicular
/// phase, which is why ovulation is placed counting *back* from the next
/// period rather than at the cycle's midpoint.
const lutealPhaseDays = 14;

const _minCycleDays = 21;
const _maxCycleDays = 45;

/// Two logged starts closer than this are the same period logged twice (or
/// "day 1" and "day 2" both logged), not two cycles.
const _samePeriodWithinDays = 10;

/// Period-start dates, oldest first, with same-day duplicates and
/// near-duplicates (see [_samePeriodWithinDays]) collapsed into the earliest.
List<DateTime> normalizedPeriodStarts(List<DateTime> periodStarts) {
  final sorted = periodStarts.map(_dateOnly).toList()..sort();
  final result = <DateTime>[];
  for (final date in sorted) {
    if (result.isNotEmpty && date.difference(result.last).inDays < _samePeriodWithinDays) {
      continue;
    }
    result.add(date);
  }
  return result;
}

/// Logged cycles (consecutive start pairs) that look like real cycles —
/// what [estimatedCycleLength] actually learns from.
List<int> usableCycleLengths(List<DateTime> periodStarts) {
  final starts = normalizedPeriodStarts(periodStarts);
  return <int>[
    for (var i = 1; i < starts.length; i++) starts[i].difference(starts[i - 1]).inDays,
  ].where((g) => g >= _minCycleDays && g <= _maxCycleDays).toList();
}

/// Whether [date] is within [_samePeriodWithinDays] of an already-logged
/// start — likely the same period logged twice.
bool isNearExistingPeriodStart(List<DateTime> periodStarts, DateTime date) {
  final d = _dateOnly(date);
  return periodStarts.any((s) => _dateOnly(s).difference(d).inDays.abs() < _samePeriodWithinDays);
}

/// Typical cycle length from the user's own history: the median of their
/// most recent (up to 6) cycles. Gaps longer than [_maxCycleDays] are
/// skipped rather than averaged in — they almost always mean a period
/// wasn't logged, and one missed log used to drag the estimate way off.
/// Falls back to the textbook 28 days with no usable history.
int estimatedCycleLength(List<DateTime> periodStarts) {
  final gaps = usableCycleLengths(periodStarts);
  if (gaps.isEmpty) return 28;

  final recent = gaps.length > 6 ? gaps.sublist(gaps.length - 6) : gaps;
  final sorted = [...recent]..sort();
  final mid = sorted.length ~/ 2;
  final median = sorted.length.isOdd ? sorted[mid].toDouble() : (sorted[mid - 1] + sorted[mid]) / 2;
  return median.round().clamp(_minCycleDays, _maxCycleDays);
}

/// 0-indexed day within the cycle on which ovulation is expected.
int ovulationDayIndex(int cycleLength) =>
    (cycleLength - lutealPhaseDays - 1).clamp(periodLengthDays, cycleLength - 1);

/// Maps a single 0-indexed day within a cycle of [cycleLength] to its phase
/// — the shared boundary rules used both by [currentCycleStatus] and by
/// `CyclePhaseWheel` (to color every day around the ring consistently).
/// "Ovulation" covers the expected ovulation day plus one day either side.
CyclePhase phaseForDayInCycle(int dayInCycle, int cycleLength) {
  final ovulation = ovulationDayIndex(cycleLength);

  if (dayInCycle < periodLengthDays) return CyclePhase.menstrual;
  if (dayInCycle < ovulation - 1) return CyclePhase.follicular;
  if (dayInCycle <= ovulation + 1) return CyclePhase.ovulation;
  return CyclePhase.luteal;
}

/// Everything the cycle screen shows about "now", computed once.
class CycleStatus {
  /// 0-indexed days since the most recent logged start. Unlike before, this
  /// does *not* wrap around once it passes [cycleLength] — a late period is
  /// reported as late, not silently treated as a new cycle.
  final int dayInCycle;
  final int cycleLength;
  final DateTime lastPeriodStart;
  final DateTime nextPeriodStart;
  final DateTime ovulationDate;

  /// The fertile window: the 5 days before ovulation plus ovulation day.
  final DateTime fertileStart;
  final DateTime fertileEnd;

  const CycleStatus({
    required this.dayInCycle,
    required this.cycleLength,
    required this.lastPeriodStart,
    required this.nextPeriodStart,
    required this.ovulationDate,
    required this.fertileStart,
    required this.fertileEnd,
  });

  /// Days past the expected start, or 0 when not late.
  int get daysLate => dayInCycle >= cycleLength ? dayInCycle - cycleLength + 1 : 0;
  bool get isLate => daysLate > 0;

  /// Days until the next expected period (0 = today), or null once late.
  int? daysUntilNextPeriod(DateTime now) =>
      isLate ? null : nextPeriodStart.difference(_dateOnly(now)).inDays;

  /// Late periods stay in the luteal phase until a new start is logged.
  CyclePhase get phase =>
      isLate ? CyclePhase.luteal : phaseForDayInCycle(dayInCycle, cycleLength);
}

/// How long after the expected start we still claim to know where the user
/// is in their cycle. Past this, the last log is too stale to say anything.
const _staleAfterDaysLate = 30;

/// Today's position in the cycle from logged period-start dates, or null
/// when nothing usable has been logged (none yet, or the most recent log is
/// so old the estimate would be meaningless).
CycleStatus? currentCycleStatus(List<DateTime> periodStarts, {DateTime? now}) {
  final starts = normalizedPeriodStarts(periodStarts);
  if (starts.isEmpty) return null;

  final today = _dateOnly(now ?? DateTime.now());
  final lastStart = starts.last;
  final cycleLength = estimatedCycleLength(starts);
  final daysSince = today.difference(lastStart).inDays;
  if (daysSince < 0) return null;
  if (daysSince >= cycleLength + _staleAfterDaysLate) return null;

  final ovulation = lastStart.add(Duration(days: ovulationDayIndex(cycleLength)));
  return CycleStatus(
    dayInCycle: daysSince,
    cycleLength: cycleLength,
    lastPeriodStart: lastStart,
    nextPeriodStart: lastStart.add(Duration(days: cycleLength)),
    ovulationDate: ovulation,
    fertileStart: ovulation.subtract(const Duration(days: 5)),
    fertileEnd: ovulation,
  );
}

/// Today's phase, or null — see [currentCycleStatus].
CyclePhase? currentPhase(List<DateTime> periodStarts, {DateTime? now}) =>
    currentCycleStatus(periodStarts, now: now)?.phase;

/// Whether [day] falls within a logged period (start + [periodLengthDays])
/// — used by the calendar to shade period days.
bool isLoggedPeriodDay(List<DateTime> periodStarts, DateTime day) {
  final d = _dateOnly(day);
  for (final start in normalizedPeriodStarts(periodStarts)) {
    final diff = d.difference(start).inDays;
    if (diff >= 0 && diff < periodLengthDays) return true;
  }
  return false;
}

/// A small, fixed, clearly-labeled estimate — not computed per-user — since
/// the luteal-phase BMR bump is real but too individually variable to claim
/// more precision than a flat, honest nudge.
int? lutealCalorieAdjustment(CyclePhase? phase) {
  return phase == CyclePhase.luteal ? 100 : null;
}
