import '../../models/custom_exercise.dart';
import '../../models/saved_food_combo.dart';
import '../../models/workout_template.dart';
import 'library_share.dart';
import 'nutrition_share.dart';
import 'share_codec.dart';
import 'workout_share.dart';

/// What a pasted code turned out to contain, so the UI can branch once.
/// Kept separate from `workout_share.dart`/`library_share.dart` themselves
/// so this dispatcher can depend on every domain share type without any of
/// them needing to depend on each other.
sealed class DecodedShare {}

class DecodedTemplateShare extends DecodedShare {
  final WorkoutTemplate template;
  DecodedTemplateShare(this.template);
}

class DecodedSplitShare extends DecodedShare {
  final SharedSplitBundle bundle;
  DecodedSplitShare(this.bundle);
}

class DecodedComboShare extends DecodedShare {
  final SavedFoodCombo combo;
  DecodedComboShare(this.combo);
}

class DecodedCustomExerciseShare extends DecodedShare {
  final CustomExercise exercise;
  DecodedCustomExerciseShare(this.exercise);
}

class DecodedLibraryShare extends DecodedShare {
  final DecodedLibraryBundle bundle;
  DecodedLibraryShare(this.bundle);
}

/// Dispatches a pasted code to the right decoder based on its prefix, so
/// the UI only needs one paste/import entry point.
DecodedShare decodeAny(String code) {
  final trimmed = code.trim();
  if (trimmed.startsWith(SharePrefix.split)) {
    return DecodedSplitShare(decodeSplitBundle(trimmed));
  }
  if (trimmed.startsWith(SharePrefix.day)) {
    return DecodedTemplateShare(decodeTemplate(trimmed));
  }
  if (trimmed.startsWith(SharePrefix.combo)) {
    return DecodedComboShare(decodeCombo(trimmed));
  }
  if (trimmed.startsWith(SharePrefix.exercise)) {
    return DecodedCustomExerciseShare(decodeCustomExercise(trimmed));
  }
  if (trimmed.startsWith(SharePrefix.library)) {
    return DecodedLibraryShare(decodeLibraryBundle(trimmed));
  }
  throw const ShareCodeException('That code looks invalid or corrupted.');
}
