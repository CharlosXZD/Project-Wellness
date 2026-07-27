/// Counts consecutive active days ending at today (or yesterday, if today
/// has no activity yet — a streak isn't broken until a full day is actually
/// skipped, so logging tomorrow morning doesn't zero out today's streak).
///
/// [activeDays] can contain any [DateTime]s (e.g. raw timestamps) — this
/// normalizes each to calendar-day granularity itself, so callers don't need
/// to dedupe or strip time-of-day first.
int computeStreak(Iterable<DateTime> activeDays, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final days = activeDays.map(_dateOnly).toSet();

  var cursor = today;
  if (!days.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!days.contains(cursor)) return 0;
  }

  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

DateTime _dateOnly(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);
