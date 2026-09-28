import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One day's activity state for [ActivityWeekStrip] — [primaryActive] is
/// this strip's main signal (food logged on Nutrition, a workout logged on
/// Training, either one on Home's combined strip); [secondaryActive] is only
/// used by Home's combined strip (the other of the two).
class ActivityDay {
  final DateTime date;
  final bool primaryActive;
  final bool secondaryActive;

  const ActivityDay({
    required this.date,
    this.primaryActive = false,
    this.secondaryActive = false,
  });
}

/// The 7 calendar days ending today, oldest first — the fixed window every
/// [ActivityWeekStrip] shows.
List<DateTime> lastSevenDays() {
  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);
  return [
    for (var i = 6; i >= 0; i--) todayMidnight.subtract(Duration(days: i))
  ];
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// A horizontal 7-day strip (oldest to today, left to right) with a small
/// dot per day marking whether something was logged — modeled after the
/// week-strip pattern common to mainstream nutrition trackers. Tap a day to
/// jump to its detail.
class ActivityWeekStrip extends StatelessWidget {
  final List<ActivityDay> days;
  final Color primaryColor;
  final Color? secondaryColor;
  final ValueChanged<DateTime> onDayTap;

  /// Shows a "Calendar" header button that opens the full month view — the
  /// strip only ever covers the last 7 days.
  final VoidCallback? onOpenCalendar;

  const ActivityWeekStrip({
    super.key,
    required this.days,
    required this.primaryColor,
    this.secondaryColor,
    required this.onDayTap,
    this.onOpenCalendar,
  }) : assert(
            days.length == 7, 'ActivityWeekStrip always shows exactly 7 days');

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();

    final strip = Row(
      children: [
        for (final day in days)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onDayTap(day.date),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _weekdayLetters[day.date.weekday - 1],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSameDay(day.date, today)
                            ? scheme.primaryContainer
                            : null,
                      ),
                      child: Text(
                        '${day.date.day}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: isSameDay(day.date, today)
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dot(active: day.primaryActive, color: primaryColor),
                        if (secondaryColor != null) ...[
                          const SizedBox(width: 3),
                          _Dot(
                              active: day.secondaryActive,
                              color: secondaryColor!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    if (onOpenCalendar == null) return strip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  DateFormat.yMMMM().format(today),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onOpenCalendar,
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('Calendar'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        strip,
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  final Color color;

  const _Dot({required this.active, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : Colors.transparent,
      ),
    );
  }
}
