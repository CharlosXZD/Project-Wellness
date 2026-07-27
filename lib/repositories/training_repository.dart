import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/db/database_helper.dart';
import '../core/health/health_service.dart';
import '../core/notifications/notification_service.dart';
import '../core/sharing/library_share.dart';
import '../data/exercise_library.dart';
import '../models/custom_exercise.dart';
import '../models/exercise_def.dart';
import '../models/weight_entry.dart';
import '../models/workout_session.dart';
import '../models/workout_split.dart';
import '../models/workout_template.dart';

class TrainingRepository extends ChangeNotifier {
  List<WeightEntry> _weightEntries = [];
  WorkoutSplit? _split;
  List<WorkoutTemplate> _templates = [];
  List<WorkoutSession> _sessions = [];
  List<CustomExercise> _customExercises = [];
  bool _loaded = false;

  List<WeightEntry> get weightEntries => _weightEntries;
  WorkoutSplit? get split => _split;
  List<WorkoutTemplate> get templates => _templates;
  List<WorkoutSession> get sessions => _sessions;
  List<CustomExercise> get customExercises => _customExercises;
  bool get isLoaded => _loaded;
  bool get hasSplit => _split != null;

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;

    final weightRows = await db.query('weight_entries', orderBy: 'date DESC');
    _weightEntries = weightRows.map(WeightEntry.fromMap).toList();

    final splitRows =
        await db.query('workout_split', where: 'id = 1', limit: 1);
    _split = splitRows.isEmpty ? null : WorkoutSplit.fromMap(splitRows.first);

    final templateRows =
        await db.query('workout_templates', orderBy: 'created_at ASC');
    final templates = <WorkoutTemplate>[];
    for (final row in templateRows) {
      final exerciseRows = await db.query(
        'template_exercises',
        where: 'template_id = ?',
        whereArgs: [row['id']],
        orderBy: 'order_index ASC',
      );
      templates.add(
        WorkoutTemplate.fromMap(
          row,
          exercises: exerciseRows.map(TemplateExercise.fromMap).toList(),
        ),
      );
    }
    _templates = templates;

    final sessionRows =
        await db.query('workout_sessions', orderBy: 'date DESC');
    final sessions = <WorkoutSession>[];
    for (final row in sessionRows) {
      final exerciseRows = await db.query(
        'session_exercises',
        where: 'session_id = ?',
        whereArgs: [row['id']],
        orderBy: 'order_index ASC',
      );
      final exercises = <SessionExercise>[];
      for (final exerciseRow in exerciseRows) {
        final setRows = await db.query(
          'session_sets',
          where: 'session_exercise_id = ?',
          whereArgs: [exerciseRow['id']],
          orderBy: 'set_index ASC',
        );
        exercises.add(
          SessionExercise.fromMap(
            exerciseRow,
            sets: setRows.map(SessionSet.fromMap).toList(),
          ),
        );
      }
      sessions.add(WorkoutSession.fromMap(row, exercises: exercises));
    }
    _sessions = sessions;

    final customExerciseRows =
        await db.query('custom_exercises', orderBy: 'created_at ASC');
    _customExercises = customExerciseRows.map(CustomExercise.fromMap).toList();

    _loaded = true;
    notifyListeners();
  }

  Future<void> addWeightEntry(WeightEntry entry) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('weight_entries', entry.toMap());
    await load();
    if (HealthService.instance.syncEnabled) {
      await HealthService.instance.writeWeight(entry.weightKg, entry.date);
    }
  }

  Future<void> deleteWeightEntry(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('weight_entries', where: 'id = ?', whereArgs: [id]);
    await load();
  }

  Future<void> saveSplit(WorkoutSplit split) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'workout_split',
      split.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _split = split;
    notifyListeners();
  }

  List<WorkoutTemplate> templatesForDay(String dayName) {
    return _templates.where((t) => t.dayName == dayName).toList();
  }

  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.insert('workout_templates', template.toMap());
      for (final exercise in template.exercises) {
        await txn.insert('template_exercises', exercise.toMap());
      }
    });
    await load();
    return template;
  }

  /// Renames [template] and/or replaces its exercise list in place. Safe to
  /// mutate — `workout_sessions.template_id` has no FK constraint and every
  /// logged session keeps its own denormalized exercise snapshot, so editing
  /// a template can never corrupt history (unlike
  /// [duplicateTemplateWithExercise], which clones instead, for a different
  /// reason — not disturbing an already-in-progress session).
  Future<WorkoutTemplate> updateTemplate(WorkoutTemplate template) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'workout_templates',
        template.toMap(),
        where: 'id = ?',
        whereArgs: [template.id],
      );
      // Full replace is simplest/safest since there's no per-exercise id
      // continuity to diff against, and the FK cascade makes the delete cheap.
      await txn.delete(
        'template_exercises',
        where: 'template_id = ?',
        whereArgs: [template.id],
      );
      for (final exercise in template.exercises) {
        await txn.insert('template_exercises', exercise.toMap());
      }
    });
    await load();
    return template;
  }

  /// Saves an imported split plus every template that came with it as one
  /// transaction, then reloads once — used by the split-share import flow
  /// so it doesn't trigger N reloads for N templates.
  Future<void> importSplitBundle(
    WorkoutSplit split,
    List<WorkoutTemplate> templates,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.insert(
        'workout_split',
        split.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final template in templates) {
        await txn.insert('workout_templates', template.toMap());
        for (final exercise in template.exercises) {
          await txn.insert('template_exercises', exercise.toMap());
        }
      }
    });
    await load();
  }

  /// Clones [original] under a fresh template id with one extra exercise
  /// appended — used when a mid-workout "add exercise" should also carry
  /// forward into future workouts of this day, without touching the
  /// original template (today's in-progress session keeps logging against
  /// [original]'s id regardless of whether this is called).
  Future<WorkoutTemplate> duplicateTemplateWithExercise(
    WorkoutTemplate original,
    ExerciseDef extra,
  ) async {
    final newTemplateId = const Uuid().v4();
    final copiedExercises = [
      for (final exercise in original.exercises)
        TemplateExercise(
          id: const Uuid().v4(),
          templateId: newTemplateId,
          exerciseName: exercise.exerciseName,
          category: exercise.category,
          orderIndex: exercise.orderIndex,
          targetSets: exercise.targetSets,
          targetReps: exercise.targetReps,
          durationSeconds: exercise.durationSeconds,
        ),
    ];
    final newExercise = TemplateExercise(
      id: const Uuid().v4(),
      templateId: newTemplateId,
      exerciseName: extra.name,
      category: extra.category,
      orderIndex: copiedExercises.length,
      durationSeconds: extra.category == 'Pilates' ? 300 : null,
    );

    return createTemplate(
      WorkoutTemplate(
        id: newTemplateId,
        dayName: original.dayName,
        name: '${original.name} (updated)',
        createdAt: DateTime.now(),
        exercises: [...copiedExercises, newExercise],
      ),
    );
  }

  Future<void> deleteTemplate(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('workout_templates', where: 'id = ?', whereArgs: [id]);
    await load();
  }

  Future<void> addSession(WorkoutSession session) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.insert('workout_sessions', session.toMap());
      for (final exercise in session.exercises) {
        await txn.insert('session_exercises', exercise.toMap());
        for (final set in exercise.sets) {
          await txn.insert('session_sets', set.toMap());
        }
      }
    });
    await load();
    // Skip today's workout reminder, if any — the user already worked out.
    await NotificationService.instance.onWorkoutLogged(session.date);
    if (HealthService.instance.syncEnabled) {
      await HealthService.instance.writeWorkout(session);
    }
  }

  /// Corrects a logged session's name/date after the fact (e.g. the wrong
  /// day got selected) — deliberately doesn't touch `session_exercises`/
  /// `session_sets`; see [updateSessionExercise]/[deleteSessionExercise] for
  /// per-exercise corrections.
  Future<void> updateSessionInfo(
    String id, {
    required String name,
    required DateTime date,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'workout_sessions',
      {'name': name, 'date': date.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    await load();
  }

  /// Relies on `session_exercises`/`session_sets`' `ON DELETE CASCADE` FKs
  /// (foreign_keys is on, see `DatabaseHelper`) to clean up child rows.
  Future<void> deleteSession(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
    await load();
  }

  /// Replaces every set for [exercise] with [sets] — full delete-then-insert
  /// like [updateTemplate] does for a template's exercises, since sets have
  /// no independent identity worth diffing against. Used by the logged-
  /// session exercise editor to correct a mistyped weight/reps or change the
  /// set count after the fact.
  Future<void> updateSessionExercise(
    SessionExercise exercise,
    List<SessionSet> sets,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete(
        'session_sets',
        where: 'session_exercise_id = ?',
        whereArgs: [exercise.id],
      );
      for (final set in sets) {
        await txn.insert('session_sets', set.toMap());
      }
    });
    await load();
  }

  /// Removes one exercise (and its sets, via cascade) from an already-logged
  /// session — for when an exercise was added by mistake or shouldn't have
  /// counted.
  Future<void> deleteSessionExercise(String sessionExerciseId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'session_exercises',
      where: 'id = ?',
      whereArgs: [sessionExerciseId],
    );
    await load();
  }

  /// Most recent previously-logged sets for [exerciseName], used to
  /// pre-fill weight/reps steppers so most sets need zero typing.
  Future<List<SessionSet>> lastSetsForExercise(String exerciseName) async {
    final db = await DatabaseHelper.instance.database;
    final sessionExerciseRows = await db.rawQuery('''
      SELECT se.id AS session_exercise_id
      FROM session_exercises se
      INNER JOIN workout_sessions ws ON ws.id = se.session_id
      WHERE se.exercise_name = ?
      ORDER BY ws.date DESC
      LIMIT 1
    ''', [exerciseName]);

    if (sessionExerciseRows.isEmpty) return [];

    final setRows = await db.query(
      'session_sets',
      where: 'session_exercise_id = ?',
      whereArgs: [sessionExerciseRows.first['session_exercise_id']],
      orderBy: 'set_index ASC',
    );
    return setRows.map(SessionSet.fromMap).toList();
  }

  double? get latestWeightKg =>
      _weightEntries.isEmpty ? null : _weightEntries.first.weightKg;

  Future<void> createCustomExercise(CustomExercise exercise) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('custom_exercises', exercise.toMap());
    await load();
  }

  Future<void> updateCustomExercise(CustomExercise exercise) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'custom_exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
    await load();
  }

  Future<void> deleteCustomExercise(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('custom_exercises', where: 'id = ?', whereArgs: [id]);
    await load();
  }

  /// Adds every exercise in [incoming] that isn't already in this user's
  /// library (matched by name, case-insensitive) — additive only, never
  /// overwrites or removes an existing exercise, matching the "fresh IDs,
  /// additive" rule every other import in docs/SHARING_SYSTEM.md follows.
  /// Returns how many were actually added.
  Future<int> mergeCustomExercises(List<CustomExercise> incoming) async {
    final toAdd = newItemsByName(
      incoming: incoming,
      existingNames: _customExercises.map((e) => e.name),
      nameOf: (e) => e.name,
    );
    if (toAdd.isEmpty) return 0;

    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      for (final exercise in toAdd) {
        await txn.insert('custom_exercises', exercise.toMap());
      }
    });
    await load();
    return toAdd.length;
  }

  /// Looks up an [ExerciseDef] by name across both the built-in library and
  /// this user's custom exercises — the single source of truth every
  /// exercise picker/logger screen should use once custom exercises exist,
  /// rather than scanning `exerciseLibrary` directly.
  ExerciseDef? exerciseDefByName(String name) {
    for (final custom in _customExercises) {
      if (custom.name == name) return custom.toExerciseDef();
    }
    for (final builtIn in exerciseLibrary) {
      if (builtIn.name == name) return builtIn;
    }
    return null;
  }
}
