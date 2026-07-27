import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/db/database_helper.dart';
import '../core/notifications/notification_service.dart';
import '../core/training/workout_summary.dart';
import '../core/units/units.dart';
import '../data/medal_catalog.dart';
import '../models/exercise_def.dart';
import '../models/workout_session.dart';
import '../models/workout_template.dart';
import 'medals_repository.dart';
import 'nutrition_repository.dart';
import 'training_repository.dart';

/// Whether an exercise logs a single duration instead of sets — an explicit
/// [ExerciseTrackingType] (set on custom exercises) always wins; built-in
/// exercises (which never set it) fall back to the original Pilates/Cardio
/// category check.
bool isDurationBasedTracking(
    {required String category, ExerciseTrackingType? trackingType}) {
  if (trackingType != null) {
    return trackingType != ExerciseTrackingType.standard;
  }
  return category == 'Pilates' || category == 'Cardio';
}

/// Whether a duration-based exercise also tracks calories burned + distance
/// (vs. just a duration, like Pilates) — same override-then-fallback rule as
/// [isDurationBasedTracking].
bool isDistanceTracking(
    {required String category, ExerciseTrackingType? trackingType}) {
  if (trackingType != null) {
    return trackingType == ExerciseTrackingType.distance;
  }
  return category == 'Cardio';
}

class ActiveWorkoutSetDraft {
  double weightKg;
  int reps;
  final SetSide? side;

  ActiveWorkoutSetDraft(
      {required this.weightKg, required this.reps, this.side});
}

class ActiveWorkoutExerciseDraft {
  final TemplateExercise template;
  final List<ActiveWorkoutSetDraft> sets;
  // Full definition (equipment/movement/video/unilateral) resolved by name
  // against the built-in library + this user's custom exercises — null only
  // for a legacy ad-hoc exercise added before custom exercises existed.
  final ExerciseDef? resolvedDef;
  int durationMinutes;
  int caloriesBurned = 0;
  double distanceKm = 0;

  ActiveWorkoutExerciseDraft({
    required this.template,
    required this.sets,
    required this.resolvedDef,
    this.durationMinutes = 5,
  });

  bool get isCardio => isDistanceTracking(
      category: template.category, trackingType: resolvedDef?.trackingType);
  bool get isDurationBased => isDurationBasedTracking(
      category: template.category, trackingType: resolvedDef?.trackingType);
  bool get isUnilateral =>
      template.unilateral || (resolvedDef?.unilateral ?? false);
  bool get isBodyweight => resolvedDef?.equipment == Equipment.bodyweight;
  String? get videoUrl => resolvedDef?.videoUrl;
}

/// The single in-progress workout, if any — owns everything that used to
/// live inside `_ActiveWorkoutScreenState` (drafts, elapsed time, pause
/// state) so it survives navigating away from `ActiveWorkoutScreen` and
/// back. Only one workout can be active at a time; starting a new one
/// (see `day_templates_screen.dart`) discards whatever was in progress.
class ActiveWorkoutRepository extends ChangeNotifier {
  WorkoutTemplate? _template;
  List<ActiveWorkoutExerciseDraft>? _drafts;
  DateTime? _startedAt;
  DateTime? _pausedAt;
  Duration _accumulatedPause = Duration.zero;
  Timer? _ticker;
  bool _isScreenVisible = false;
  Timer? _snapshotDebounce;

  WorkoutTemplate? get template => _template;
  List<ActiveWorkoutExerciseDraft>? get drafts => _drafts;
  bool get hasActiveWorkout => _template != null;
  bool get isPaused => _pausedAt != null;

  /// Whether `ActiveWorkoutScreen` is currently the visible top route —
  /// toggled by its `RouteAware` subscription to [activeWorkoutRouteObserver
  /// in active_workout_route_observer.dart]. The persistent bar only shows
  /// when there's an active workout *and* this is false.
  bool get isScreenVisible => _isScreenVisible;

  /// [RouteAware] callbacks (`didPush`/`didPop`/etc.) can fire synchronously
  /// during a build/navigation transition — e.g. `RouteObserver.subscribe`
  /// calls `didPush()` immediately from inside `didChangeDependencies`,
  /// which is itself part of the build pipeline. Calling `notifyListeners()`
  /// synchronously from there tries to rebuild *other* widgets (like
  /// `ActiveWorkoutBar`) mid-build, which throws — the value is applied
  /// immediately (`isScreenVisible` is correct right away) but the
  /// notification that triggers other widgets to rebuild is deferred to
  /// just after the current frame finishes.
  void setScreenVisible(bool visible) {
    if (_isScreenVisible == visible) return;
    _isScreenVisible = visible;
    SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  Duration get elapsed {
    if (_startedAt == null) return Duration.zero;
    final end = _pausedAt ?? DateTime.now();
    return end.difference(_startedAt!) - _accumulatedPause;
  }

  /// A rough 0..1 "how far through the workout" proxy for the persistent
  /// bar's progress indicator — the app doesn't otherwise track a real
  /// completion percentage, so this counts exercises with at least one
  /// non-zero-weight set logged against the total.
  double get progressFraction {
    final drafts = _drafts;
    if (drafts == null || drafts.isEmpty) return 0;
    final started = drafts
        .where((d) => d.sets.any((s) => s.weightKg > 0 || s.reps > 0))
        .length;
    return started / drafts.length;
  }

  Future<void> start(
      WorkoutTemplate template, TrainingRepository trainingRepo) async {
    _template = template;
    _startedAt = DateTime.now();
    _pausedAt = null;
    _accumulatedPause = Duration.zero;

    final drafts = <ActiveWorkoutExerciseDraft>[];
    for (final exercise in template.exercises) {
      drafts.add(await _buildDraftFor(trainingRepo, exercise));
    }
    _drafts = drafts;

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused) notifyListeners();
    });

    notifyListeners();
    unawaited(_persistSnapshot());
  }

  /// Restores the in-progress workout `start()` left on disk, if any — call
  /// once at app launch, after [trainingRepo] has loaded (its exercise
  /// library is needed to re-resolve each draft's [ActiveWorkoutExerciseDraft
  /// .resolvedDef]). A crash or an unwanted OS/user restart mid-workout
  /// otherwise loses the whole in-progress session, since until now nothing
  /// backed it beyond this in-memory object. Silent no-op if there's
  /// nothing to restore, a workout is already active, or the saved snapshot
  /// can't be parsed (e.g. left over from an incompatible earlier version).
  Future<bool> restoreIfAny(TrainingRepository trainingRepo) async {
    if (_template != null) return false;

    final db = await DatabaseHelper.instance.database;
    final rows =
        await db.query('active_workout_snapshot', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return false;

    try {
      final map =
          jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
      final template = _templateFromSnapshotMap(
          (map['template'] as Map).cast<String, dynamic>());
      final drafts = (map['drafts'] as List)
          .map((d) => _draftFromSnapshotMap(
              (d as Map).cast<String, dynamic>(), trainingRepo))
          .toList();

      _template = template;
      _drafts = drafts;
      _startedAt = DateTime.parse(map['started_at'] as String);
      _pausedAt = map['paused_at'] != null
          ? DateTime.parse(map['paused_at'] as String)
          : null;
      _accumulatedPause = Duration(
          milliseconds: (map['accumulated_pause_ms'] as num?)?.toInt() ?? 0);

      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!isPaused) notifyListeners();
      });

      notifyListeners();
      return true;
    } catch (_) {
      // Corrupt or unreadable snapshot — drop it rather than let a bad
      // restore block (or crash) every future launch.
      await _clearSnapshot();
      return false;
    }
  }

  void pause() {
    if (_pausedAt != null) return;
    _pausedAt = DateTime.now();
    notifyListeners();
    unawaited(_persistSnapshot());
  }

  void resume() {
    if (_pausedAt == null) return;
    _accumulatedPause += DateTime.now().difference(_pausedAt!);
    _pausedAt = null;
    notifyListeners();
    unawaited(_persistSnapshot());
  }

  /// Ends the in-progress workout without saving anything — used when the
  /// user chooses to discard it in favor of starting a different one.
  void discard() {
    _ticker?.cancel();
    _ticker = null;
    _snapshotDebounce?.cancel();
    _template = null;
    _drafts = null;
    _startedAt = null;
    _pausedAt = null;
    _accumulatedPause = Duration.zero;
    _isScreenVisible = false;
    notifyListeners();
    unawaited(_clearSnapshot());
  }

  /// Builds a single exercise's draft — Pilates/Cardio entries get a
  /// duration default (no sets to track), unilateral exercises get L/R set
  /// pairs, everything else gets the usual weight/reps prefill from history
  /// (falling back to the template's baseline, then to 0).
  Future<ActiveWorkoutExerciseDraft> _buildDraftFor(
    TrainingRepository repo,
    TemplateExercise exercise,
  ) async {
    final resolvedDef = repo.exerciseDefByName(exercise.exerciseName);

    if (isDurationBasedTracking(
        category: exercise.category, trackingType: resolvedDef?.trackingType)) {
      return ActiveWorkoutExerciseDraft(
        template: exercise,
        sets: [],
        resolvedDef: resolvedDef,
        durationMinutes: ((exercise.durationSeconds ?? 300) / 60).round(),
      );
    }

    final lastSets = await repo.lastSetsForExercise(exercise.exerciseName);

    if (exercise.unilateral || (resolvedDef?.unilateral ?? false)) {
      final leftSets = _prefillSets(lastSets, SetSide.left, exercise);
      final rightSets = _prefillSets(lastSets, SetSide.right, exercise);
      final sets = <ActiveWorkoutSetDraft>[];
      for (var i = 0; i < exercise.targetSets; i++) {
        sets.add(leftSets[i]);
        sets.add(rightSets[i]);
      }
      return ActiveWorkoutExerciseDraft(
          template: exercise, sets: sets, resolvedDef: resolvedDef);
    }

    final sets = _prefillSets(lastSets, null, exercise);
    return ActiveWorkoutExerciseDraft(
        template: exercise, sets: sets, resolvedDef: resolvedDef);
  }

  List<ActiveWorkoutSetDraft> _prefillSets(
    List<SessionSet> lastSets,
    SetSide? side,
    TemplateExercise exercise,
  ) {
    final relevant = side == null
        ? lastSets
        : lastSets.where((s) => s.side == side).toList();
    final sets = <ActiveWorkoutSetDraft>[];
    for (var i = 0; i < exercise.targetSets; i++) {
      if (i < relevant.length) {
        sets.add(ActiveWorkoutSetDraft(
            weightKg: relevant[i].weightKg,
            reps: relevant[i].reps,
            side: side));
      } else if (relevant.isNotEmpty) {
        sets.add(ActiveWorkoutSetDraft(
            weightKg: relevant.last.weightKg,
            reps: relevant.last.reps,
            side: side));
      } else {
        sets.add(ActiveWorkoutSetDraft(
          weightKg: exercise.targetWeightKg ?? 0.0,
          reps: exercise.targetReps,
          side: side,
        ));
      }
    }
    return sets;
  }

  Future<void> addExercise(
    TrainingRepository repo,
    ExerciseDef picked, {
    required bool saveAsTemplate,
  }) async {
    final template = _template;
    final drafts = _drafts;
    if (template == null || drafts == null) return;

    final newExercise = TemplateExercise(
      id: const Uuid().v4(),
      templateId: template.id,
      exerciseName: picked.name,
      category: picked.category,
      orderIndex: drafts.length,
      durationSeconds: isDurationBasedTracking(
              category: picked.category, trackingType: picked.trackingType)
          ? 300
          : null,
    );
    final draft = await _buildDraftFor(repo, newExercise);
    drafts.add(draft);
    notifyListeners();
    _scheduleSnapshot();

    if (saveAsTemplate) {
      await repo.duplicateTemplateWithExercise(template, picked);
    }
  }

  void adjustWeight(ActiveWorkoutSetDraft set, double delta) {
    set.weightKg = Units.roundStorage((set.weightKg + delta).clamp(0, 500));
    notifyListeners();
    _scheduleSnapshot();
  }

  void adjustReps(ActiveWorkoutSetDraft set, int delta) {
    set.reps = (set.reps + delta).clamp(0, 100);
    notifyListeners();
    _scheduleSnapshot();
  }

  void addSet(ActiveWorkoutExerciseDraft draft) {
    if (draft.isUnilateral) {
      final lastLeft = draft.sets.lastWhere(
        (s) => s.side == SetSide.left,
        orElse: () => ActiveWorkoutSetDraft(
            weightKg: 0.0, reps: draft.template.targetReps),
      );
      final lastRight = draft.sets.lastWhere(
        (s) => s.side == SetSide.right,
        orElse: () => ActiveWorkoutSetDraft(
            weightKg: 0.0, reps: draft.template.targetReps),
      );
      draft.sets.add(ActiveWorkoutSetDraft(
          weightKg: lastLeft.weightKg,
          reps: lastLeft.reps,
          side: SetSide.left));
      draft.sets.add(ActiveWorkoutSetDraft(
          weightKg: lastRight.weightKg,
          reps: lastRight.reps,
          side: SetSide.right));
    } else {
      final last = draft.sets.isNotEmpty ? draft.sets.last : null;
      draft.sets.add(ActiveWorkoutSetDraft(
        weightKg: last?.weightKg ?? 0.0,
        reps: last?.reps ?? draft.template.targetReps,
      ));
    }
    notifyListeners();
    _scheduleSnapshot();
  }

  void removeSet(ActiveWorkoutExerciseDraft draft, ActiveWorkoutSetDraft set) {
    if (draft.sets.length <= 1) return;
    draft.sets.remove(set);
    notifyListeners();
    _scheduleSnapshot();
  }

  void removeExercise(ActiveWorkoutExerciseDraft draft) {
    _drafts?.remove(draft);
    notifyListeners();
    _scheduleSnapshot();
  }

  /// Reorders exercises within the in-progress workout — wired to
  /// `ReorderableListView.onReorderItem`, which (unlike the deprecated
  /// `onReorder`) already hands back a `newIndex` that accounts for the
  /// dragged item's removal, so no manual adjustment is needed here.
  void reorderExercise(int oldIndex, int newIndex) {
    final drafts = _drafts;
    if (drafts == null) return;
    drafts.insert(newIndex, drafts.removeAt(oldIndex));
    notifyListeners();
    _scheduleSnapshot();
  }

  void adjustDuration(ActiveWorkoutExerciseDraft draft, int deltaMinutes) {
    draft.durationMinutes =
        (draft.durationMinutes + deltaMinutes).clamp(1, 180);
    notifyListeners();
    _scheduleSnapshot();
  }

  void adjustCalories(ActiveWorkoutExerciseDraft draft, int delta) {
    draft.caloriesBurned = (draft.caloriesBurned + delta).clamp(0, 5000);
    notifyListeners();
    _scheduleSnapshot();
  }

  void adjustDistance(ActiveWorkoutExerciseDraft draft, double delta) {
    draft.distanceKm =
        Units.roundStorage((draft.distanceKm + delta).clamp(0, 500));
    notifyListeners();
    _scheduleSnapshot();
  }

  /// Persists the in-progress workout as a logged session, evaluates
  /// medals, and clears the active workout — the one-stop call
  /// `ActiveWorkoutScreen`'s Finish button makes. Returns the saved
  /// session, its progress summary, and any newly-unlocked medal titles.
  Future<(WorkoutSession, List<ExerciseProgress>, List<String>)> finish({
    required TrainingRepository trainingRepo,
    required MedalsRepository medalsRepo,
    required NutritionRepository nutritionRepo,
  }) async {
    final template = _template!;
    final drafts = _drafts!;

    final sessionId = const Uuid().v4();
    final sessionExercises = <SessionExercise>[];
    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      final sessionExerciseId = const Uuid().v4();
      final sets = draft.isDurationBased
          ? const <SessionSet>[]
          : <SessionSet>[
              for (var s = 0; s < draft.sets.length; s++)
                SessionSet(
                  id: const Uuid().v4(),
                  sessionExerciseId: sessionExerciseId,
                  setIndex: draft.isUnilateral ? s ~/ 2 : s,
                  weightKg: draft.sets[s].weightKg,
                  reps: draft.sets[s].reps,
                  side: draft.sets[s].side,
                ),
            ];
      sessionExercises.add(
        SessionExercise(
          id: sessionExerciseId,
          sessionId: sessionId,
          exerciseName: draft.template.exerciseName,
          orderIndex: i,
          durationSeconds:
              draft.isDurationBased ? draft.durationMinutes * 60 : null,
          caloriesBurned: draft.isCardio ? draft.caloriesBurned : null,
          distanceKm: draft.isCardio ? draft.distanceKm : null,
          sets: sets,
        ),
      );
    }

    final session = WorkoutSession(
      id: sessionId,
      templateId: template.id,
      dayName: template.dayName,
      name: template.name,
      date: DateTime.now(),
      durationMinutes: elapsed.inMinutes,
      exercises: sessionExercises,
    );

    final priorSessions = trainingRepo.sessions;
    final summary = buildWorkoutSummary(
      finished: session,
      priorSessions: priorSessions,
      template: template,
    );

    await trainingRepo.addSession(session);

    final newlyUnlocked = await medalsRepo.evaluate(MedalContext(
      sessions: trainingRepo.sessions,
      weightEntries: trainingRepo.weightEntries,
      goalHistory: nutritionRepo.goalHistory,
      nutritionEntries: nutritionRepo.entries,
    ));
    // Fired here too (not just via the summary screen's banner) so an
    // unlock still notifies if the app gets backgrounded before the user
    // sees the post-workout screen.
    for (final medal in newlyUnlocked) {
      unawaited(NotificationService.instance.notifyMedalUnlocked(medal.title));
    }

    discard();

    return (session, summary, newlyUnlocked.map((m) => m.title).toList());
  }

  /// Debounces disk writes so rapid-fire taps (e.g. holding the weight
  /// stepper) don't hit SQLite on every single delta — the snapshot only
  /// needs to be a few hundred milliseconds fresh, not byte-for-byte
  /// current, to do its job of surviving a crash or unwanted restart.
  void _scheduleSnapshot() {
    _snapshotDebounce?.cancel();
    _snapshotDebounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_persistSnapshot());
    });
  }

  /// Writes the snapshot immediately, skipping the debounce — called when
  /// the app is backgrounded (see `_AppLockGateState` in app.dart), since
  /// that's the last reliable moment before the OS can kill the process
  /// outright and a pending debounced write would never get to run.
  Future<void> flushSnapshot() {
    _snapshotDebounce?.cancel();
    return _persistSnapshot();
  }

  Future<void> _persistSnapshot() async {
    final template = _template;
    final drafts = _drafts;
    final startedAt = _startedAt;
    if (template == null || drafts == null || startedAt == null) return;

    final data = jsonEncode({
      'template': _templateToSnapshotMap(template),
      'started_at': startedAt.toIso8601String(),
      'paused_at': _pausedAt?.toIso8601String(),
      'accumulated_pause_ms': _accumulatedPause.inMilliseconds,
      'drafts': drafts.map(_draftToSnapshotMap).toList(),
    });

    final db = await DatabaseHelper.instance.database;
    // Re-check after the `await` above: if `discard()`/`finish()` ran while
    // this write was in flight, don't let a stale snapshot land after
    // `_clearSnapshot()` already ran and resurrect a finished/discarded
    // workout on the next launch.
    if (_template == null) return;
    await db.insert(
      'active_workout_snapshot',
      {'id': 1, 'data': data, 'saved_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _clearSnapshot() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('active_workout_snapshot', where: 'id = 1');
  }

  Map<String, Object?> _templateToSnapshotMap(WorkoutTemplate template) => {
        ...template.toMap(),
        'exercises': template.exercises.map((e) => e.toMap()).toList(),
      };

  WorkoutTemplate _templateFromSnapshotMap(Map<String, dynamic> map) {
    final exercises = (map['exercises'] as List)
        .map(
            (e) => TemplateExercise.fromMap((e as Map).cast<String, dynamic>()))
        .toList();
    return WorkoutTemplate.fromMap(map.cast<String, Object?>(),
        exercises: exercises);
  }

  Map<String, Object?> _draftToSnapshotMap(ActiveWorkoutExerciseDraft draft) =>
      {
        'template_exercise': draft.template.toMap(),
        'duration_minutes': draft.durationMinutes,
        'calories_burned': draft.caloriesBurned,
        'distance_km': draft.distanceKm,
        'sets': draft.sets
            .map((s) => {
                  'weight_kg': s.weightKg,
                  'reps': s.reps,
                  'side': s.side == SetSide.left
                      ? 'L'
                      : s.side == SetSide.right
                          ? 'R'
                          : null,
                })
            .toList(),
      };

  ActiveWorkoutExerciseDraft _draftFromSnapshotMap(
    Map<String, dynamic> map,
    TrainingRepository trainingRepo,
  ) {
    final templateExercise = TemplateExercise.fromMap(
        (map['template_exercise'] as Map).cast<String, dynamic>());
    final sets = (map['sets'] as List).map((raw) {
      final s = (raw as Map).cast<String, dynamic>();
      final sideCode = s['side'] as String?;
      return ActiveWorkoutSetDraft(
        weightKg: (s['weight_kg'] as num).toDouble(),
        reps: (s['reps'] as num).toInt(),
        side: sideCode == 'L'
            ? SetSide.left
            : sideCode == 'R'
                ? SetSide.right
                : null,
      );
    }).toList();

    return ActiveWorkoutExerciseDraft(
      template: templateExercise,
      sets: sets,
      resolvedDef:
          trainingRepo.exerciseDefByName(templateExercise.exerciseName),
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 5,
    )
      ..caloriesBurned = (map['calories_burned'] as num?)?.toInt() ?? 0
      ..distanceKm = (map['distance_km'] as num?)?.toDouble() ?? 0;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _snapshotDebounce?.cancel();
    super.dispose();
  }
}
