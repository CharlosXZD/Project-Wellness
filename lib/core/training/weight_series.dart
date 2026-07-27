import '../../models/user_profile.dart';
import '../../models/weight_entry.dart';

/// A single point in a weight trend chart. Either a manually logged
/// [WeightEntry] or the baseline weight captured during onboarding.
class WeightPoint {
  final DateTime date;
  final double weightKg;
  final bool isBaseline;

  const WeightPoint({
    required this.date,
    required this.weightKg,
    this.isBaseline = false,
  });
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Builds the full weight history in ascending date order, prepending the
/// onboarding weight as the baseline/first point so trend charts always
/// have a starting reference — unless a logged entry already exists for
/// that same day.
List<WeightPoint> buildWeightSeries({
  required UserProfile? profile,
  required List<WeightEntry> weightEntries,
}) {
  final sorted = [...weightEntries]..sort((a, b) => a.date.compareTo(b.date));

  final points = <WeightPoint>[];
  if (profile != null && !sorted.any((e) => _isSameDay(e.date, profile.createdAt))) {
    points.add(WeightPoint(
      date: profile.createdAt,
      weightKg: profile.weightKg,
      isBaseline: true,
    ));
  }
  points.addAll(sorted.map((e) => WeightPoint(date: e.date, weightKg: e.weightKg)));
  return points;
}
