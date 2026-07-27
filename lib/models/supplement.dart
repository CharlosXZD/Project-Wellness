class Supplement {
  final String id;
  final String name;
  final String dosage;
  final String? notes;
  final DateTime createdAt;

  const Supplement({
    required this.id,
    required this.name,
    required this.dosage,
    this.notes,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Supplement.fromMap(Map<String, Object?> map) {
    return Supplement(
      id: map['id'] as String,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
