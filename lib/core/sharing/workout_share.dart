import 'package:uuid/uuid.dart';

import '../../models/custom_exercise.dart';
import '../../models/exercise_def.dart';
import '../../models/workout_split.dart';
import '../../models/workout_template.dart';
import 'share_codec.dart';

/// A decoded split share: the split record plus every template that
/// belongs to one of its days.
class SharedSplitBundle {
  final WorkoutSplit split;
  final List<WorkoutTemplate> templates;

  const SharedSplitBundle({required this.split, required this.templates});
}

Map<String, dynamic> _exerciseToJson(TemplateExercise e) => {
      'exerciseName': e.exerciseName,
      'category': e.category,
      'orderIndex': e.orderIndex,
      'targetSets': e.targetSets,
      'targetReps': e.targetReps,
    };

TemplateExercise _exerciseFromJson(
  Map<String, dynamic> json, {
  required String templateId,
}) {
  return TemplateExercise(
    id: const Uuid().v4(),
    templateId: templateId,
    exerciseName: json['exerciseName'] as String,
    category: json['category'] as String,
    orderIndex: (json['orderIndex'] as num).toInt(),
    targetSets: (json['targetSets'] as num?)?.toInt() ?? 3,
    targetReps: (json['targetReps'] as num?)?.toInt() ?? 10,
  );
}

Map<String, dynamic> _templateToJson(WorkoutTemplate template) => {
      'dayName': template.dayName,
      'name': template.name,
      'exercises': template.exercises.map(_exerciseToJson).toList(),
    };

WorkoutTemplate _templateFromJson(Map<String, dynamic> json) {
  final templateId = const Uuid().v4();
  final exerciseList = (json['exercises'] as List)
      .map((e) => _exerciseFromJson(
            e as Map<String, dynamic>,
            templateId: templateId,
          ))
      .toList();
  return WorkoutTemplate(
    id: templateId,
    dayName: json['dayName'] as String,
    name: json['name'] as String,
    createdAt: DateTime.now(),
    exercises: exerciseList,
  );
}

/// Encodes a single day's workout template into a short shareable code.
String encodeTemplate(WorkoutTemplate template) {
  return encodePayload(_templateToJson(template), SharePrefix.day);
}

WorkoutTemplate decodeTemplate(String code) {
  final decoded = decodePayload(code);
  if (decoded.prefix != SharePrefix.day) {
    throw const ShareCodeException('That code is not a workout share.');
  }
  return _templateFromJson(decoded.json);
}

/// Encodes an entire split (its day names) plus every template that
/// belongs to one of those days.
String encodeSplitBundle(
    WorkoutSplit split, List<WorkoutTemplate> allTemplates) {
  final templates =
      allTemplates.where((t) => split.dayNames.contains(t.dayName)).toList();
  final json = {
    'splitType': split.type.name,
    'name': split.name,
    'dayNames': split.dayNames,
    'templates': templates.map(_templateToJson).toList(),
  };
  return encodePayload(json, SharePrefix.split);
}

SharedSplitBundle decodeSplitBundle(String code) {
  final decoded = decodePayload(code);
  if (decoded.prefix != SharePrefix.split) {
    throw const ShareCodeException('That code is not a split share.');
  }
  final json = decoded.json;
  final split = WorkoutSplit(
    type: SplitType.values.firstWhere(
      (t) => t.name == json['splitType'],
      orElse: () => SplitType.custom,
    ),
    name: json['name'] as String,
    dayNames: (json['dayNames'] as List).map((d) => d as String).toList(),
    createdAt: DateTime.now(),
  );
  final templates = (json['templates'] as List)
      .map((t) => _templateFromJson(t as Map<String, dynamic>))
      .toList();
  return SharedSplitBundle(split: split, templates: templates);
}

Map<String, dynamic> customExerciseToJson(CustomExercise exercise) => {
      'name': exercise.name,
      'category': exercise.category,
      'equipment': exercise.equipment.name,
      'movement': exercise.movement?.name,
      'unilateral': exercise.unilateral,
      'videoUrl': exercise.videoUrl,
      'trackingType': exercise.trackingType?.name,
    };

CustomExercise customExerciseFromJson(Map<String, dynamic> json) {
  return CustomExercise(
    id: const Uuid().v4(),
    name: json['name'] as String,
    category: json['category'] as String,
    equipment: Equipment.values.firstWhere(
      (e) => e.name == json['equipment'],
      orElse: () => Equipment.other,
    ),
    movement: json['movement'] == null
        ? null
        : MovementBadge.values.firstWhere(
            (m) => m.name == json['movement'],
            orElse: () => MovementBadge.hold,
          ),
    unilateral: json['unilateral'] as bool? ?? false,
    videoUrl: json['videoUrl'] as String?,
    trackingType: json['trackingType'] == null
        ? null
        : ExerciseTrackingType.values.firstWhere(
            (t) => t.name == json['trackingType'],
            orElse: () => ExerciseTrackingType.standard,
          ),
    createdAt: DateTime.now(),
  );
}

/// Encodes a single personal exercise into a short shareable code — e.g. so
/// a friend can send you one they made, for you to review and potentially
/// hand-add into the built-in library later (see docs/SHARING_SYSTEM.md).
String encodeCustomExercise(CustomExercise exercise) {
  return encodePayload(customExerciseToJson(exercise), SharePrefix.exercise);
}

CustomExercise decodeCustomExercise(String code) {
  final decoded = decodePayload(code);
  if (decoded.prefix != SharePrefix.exercise) {
    throw const ShareCodeException(
        'That code is not a personal exercise share.');
  }
  return customExerciseFromJson(decoded.json);
}
