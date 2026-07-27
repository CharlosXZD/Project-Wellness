class WeightEntry {
  final String id;
  final DateTime date;
  final double weightKg;
  final String? note;

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
    this.note,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight_kg': weightKg,
      'note': note,
    };
  }

  factory WeightEntry.fromMap(Map<String, Object?> map) {
    return WeightEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      weightKg: (map['weight_kg'] as num).toDouble(),
      note: map['note'] as String?,
    );
  }
}
