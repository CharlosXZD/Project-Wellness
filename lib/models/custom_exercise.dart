import 'exercise_def.dart';

/// A user-created exercise, persisted locally (see docs/SHARING_SYSTEM.md
/// for how these travel between devices). Icon and form-video are expressed
/// through the same equipment/movement/videoUrl vocabulary as the built-in
/// `exerciseLibrary` — see [toExerciseDef] — rather than uploaded media, so
/// custom exercises render identically everywhere an [ExerciseDef] is
/// already handled (`ExerciseIcon`, pickers, the active workout screen).
class CustomExercise {
  final String id;
  final String name;
  final String category;
  final Equipment equipment;
  final MovementBadge? movement;
  final bool unilateral;
  final String? videoUrl;
  final ExerciseTrackingType? trackingType;
  final DateTime createdAt;

  const CustomExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    this.movement,
    this.unilateral = false,
    this.videoUrl,
    this.trackingType,
    required this.createdAt,
  });

  ExerciseDef toExerciseDef() => ExerciseDef(
        name: name,
        category: category,
        equipment: equipment,
        movement: movement,
        videoUrl: videoUrl,
        unilateral: unilateral,
        trackingType: trackingType,
      );

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'equipment': equipment.name,
      'movement': movement?.name,
      'unilateral': unilateral ? 1 : 0,
      'video_url': videoUrl,
      'tracking_type': trackingType?.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomExercise.fromMap(Map<String, Object?> map) {
    return CustomExercise(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      equipment: Equipment.values.firstWhere(
        (e) => e.name == map['equipment'],
        orElse: () => Equipment.other,
      ),
      movement: map['movement'] == null
          ? null
          : MovementBadge.values.firstWhere(
              (m) => m.name == map['movement'],
              orElse: () => MovementBadge.hold,
            ),
      unilateral: (map['unilateral'] as num?) == 1,
      videoUrl: map['video_url'] as String?,
      trackingType: map['tracking_type'] == null
          ? null
          : ExerciseTrackingType.values.firstWhere(
              (t) => t.name == map['tracking_type'],
              orElse: () => ExerciseTrackingType.standard,
            ),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
