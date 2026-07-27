class CycleEntry {
  final String id;
  final DateTime date;
  final String? note;

  const CycleEntry({
    required this.id,
    required this.date,
    this.note,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory CycleEntry.fromMap(Map<String, Object?> map) {
    return CycleEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }
}
