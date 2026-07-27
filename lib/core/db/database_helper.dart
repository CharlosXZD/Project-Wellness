import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final directory = await getApplicationSupportDirectory();
    final path = join(directory.path, 'project_wellness.db');

    return openDatabase(
      path,
      version: 23,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        height_cm REAL NOT NULL,
        weight_kg REAL NOT NULL,
        sex TEXT,
        created_at TEXT NOT NULL,
        date_of_birth TEXT,
        initial_activity_level TEXT,
        precise_calorie_tracking_enabled INTEGER NOT NULL DEFAULT 0,
        job_activity_level TEXT,
        exercise_days_per_week INTEGER,
        exercise_intensity TEXT,
        workout_nudge_dismissed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE food_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        name TEXT NOT NULL,
        calories REAL NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        fiber_g REAL,
        sugar_g REAL,
        sodium_mg REAL,
        grams REAL
      )
    ''');

    await _createWorkoutTables(db);
    await _createNutritionTables(db);
    await _createAppSettingsTable(db);
    await _createCycleTable(db);
    await _createCustomExercisesTable(db);
    await _createMedalsTables(db);
    await _createPersonalFoodsTable(db);
    await _createActiveWorkoutSnapshotTable(db);
    await _createScannedProductsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS exercises');
      await db.execute('DROP TABLE IF EXISTS workouts');
      await _createWorkoutTables(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE profile ADD COLUMN sex TEXT');
      await db.execute('ALTER TABLE food_entries ADD COLUMN grams REAL');
      await _createNutritionTables(db);
    }
    if (oldVersion < 4) {
      final goalColumns =
          await db.rawQuery('PRAGMA table_info(nutrition_goal)');
      final hasCustomDelta =
          goalColumns.any((c) => c['name'] == 'custom_calorie_delta');
      if (!hasCustomDelta) {
        await db.execute(
            'ALTER TABLE nutrition_goal ADD COLUMN custom_calorie_delta REAL');
      }

      await _createFoodCombosTable(db);

      final hasSavedSnacks = (await db.query(
        'sqlite_master',
        where: "type = 'table' AND name = 'saved_snacks'",
      ))
          .isNotEmpty;
      if (hasSavedSnacks) {
        await db.execute('''
          INSERT INTO saved_food_combos
            (id, name, default_meal_type, ingredients_json, calories, protein_g, carbs_g, fat_g, created_at)
          SELECT id, name, 'snack', NULL, calories, protein_g, carbs_g, fat_g, created_at
          FROM saved_snacks
        ''');
        await db.execute('DROP TABLE saved_snacks');
      }
    }
    if (oldVersion < 5) {
      await _createAppSettingsTable(db);
    }
    if (oldVersion < 6) {
      await _createAppSettingsTable(db);
      final settingsColumns =
          await db.rawQuery('PRAGMA table_info(app_settings)');
      final settingsColumnNames = settingsColumns.map((c) => c['name']).toSet();
      if (!settingsColumnNames.contains('theme_mode')) {
        await db.execute(
          "ALTER TABLE app_settings ADD COLUMN theme_mode TEXT NOT NULL DEFAULT 'system'",
        );
      }
      if (!settingsColumnNames.contains('unit_system')) {
        await db.execute(
          "ALTER TABLE app_settings ADD COLUMN unit_system TEXT NOT NULL DEFAULT 'metric'",
        );
      }

      final profileColumns = await db.rawQuery('PRAGMA table_info(profile)');
      final hasDateOfBirth =
          profileColumns.any((c) => c['name'] == 'date_of_birth');
      if (!hasDateOfBirth) {
        await db.execute('ALTER TABLE profile ADD COLUMN date_of_birth TEXT');
      }
      await db.execute('''
        UPDATE profile SET date_of_birth = date('now', '-' || age || ' years')
        WHERE date_of_birth IS NULL
      ''');
    }
    if (oldVersion < 7) {
      await _createAppSettingsTable(db);
      final settingsColumns =
          await db.rawQuery('PRAGMA table_info(app_settings)');
      final settingsColumnNames = settingsColumns.map((c) => c['name']).toSet();
      for (final entry in _reminderColumnDefaults.entries) {
        if (!settingsColumnNames.contains(entry.key)) {
          await db.execute(
            'ALTER TABLE app_settings ADD COLUMN ${entry.key} INTEGER NOT NULL DEFAULT ${entry.value}',
          );
        }
      }
    }
    if (oldVersion < 8) {
      await _createAppSettingsTable(db);
      final settingsColumns =
          await db.rawQuery('PRAGMA table_info(app_settings)');
      final settingsColumnNames = settingsColumns.map((c) => c['name']).toSet();
      for (final entry in _reminderColumnDefaults.entries) {
        if (!settingsColumnNames.contains(entry.key)) {
          await db.execute(
            'ALTER TABLE app_settings ADD COLUMN ${entry.key} INTEGER NOT NULL DEFAULT ${entry.value}',
          );
        }
      }
    }
    if (oldVersion < 9) {
      await _createAppSettingsTable(db);
      final settingsColumns =
          await db.rawQuery('PRAGMA table_info(app_settings)');
      final settingsColumnNames = settingsColumns.map((c) => c['name']).toSet();
      if (!settingsColumnNames.contains('health_sync_enabled')) {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN health_sync_enabled INTEGER NOT NULL DEFAULT 0',
        );
      }
    }
    if (oldVersion < 10) {
      await _createAppSettingsTable(db);
      final settingsColumns =
          await db.rawQuery('PRAGMA table_info(app_settings)');
      final settingsColumnNames = settingsColumns.map((c) => c['name']).toSet();
      if (!settingsColumnNames.contains('app_lock_enabled')) {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN app_lock_enabled INTEGER NOT NULL DEFAULT 0',
        );
      }
    }
    if (oldVersion < 11) {
      await _createCycleTable(db);

      await _createAppSettingsTable(db);
      final settingsColumns =
          await db.rawQuery('PRAGMA table_info(app_settings)');
      final settingsColumnNames = settingsColumns.map((c) => c['name']).toSet();
      if (!settingsColumnNames.contains('cycle_tracking_enabled')) {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN cycle_tracking_enabled INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (!settingsColumnNames.contains('cycle_adjust_calories')) {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN cycle_adjust_calories INTEGER NOT NULL DEFAULT 0',
        );
      }

      final templateExerciseColumns =
          await db.rawQuery('PRAGMA table_info(template_exercises)');
      if (!templateExerciseColumns
          .any((c) => c['name'] == 'duration_seconds')) {
        await db.execute(
          'ALTER TABLE template_exercises ADD COLUMN duration_seconds INTEGER',
        );
      }
      final sessionExerciseColumns =
          await db.rawQuery('PRAGMA table_info(session_exercises)');
      if (!sessionExerciseColumns.any((c) => c['name'] == 'duration_seconds')) {
        await db.execute(
          'ALTER TABLE session_exercises ADD COLUMN duration_seconds INTEGER',
        );
      }
    }
    if (oldVersion < 12) {
      await _createAppSettingsTable(db);
      final settingsColumns =
          await db.rawQuery('PRAGMA table_info(app_settings)');
      final settingsColumnNames = settingsColumns.map((c) => c['name']).toSet();
      if (!settingsColumnNames.contains('pin_hash')) {
        await db.execute('ALTER TABLE app_settings ADD COLUMN pin_hash TEXT');
      }
      if (!settingsColumnNames.contains('pin_salt')) {
        await db.execute('ALTER TABLE app_settings ADD COLUMN pin_salt TEXT');
      }
    }
    if (oldVersion < 13) {
      final sessionSetColumns =
          await db.rawQuery('PRAGMA table_info(session_sets)');
      if (!sessionSetColumns.any((c) => c['name'] == 'side')) {
        await db.execute('ALTER TABLE session_sets ADD COLUMN side TEXT');
      }
      final sessionExerciseColumns =
          await db.rawQuery('PRAGMA table_info(session_exercises)');
      if (!sessionExerciseColumns.any((c) => c['name'] == 'calories_burned')) {
        await db.execute(
          'ALTER TABLE session_exercises ADD COLUMN calories_burned INTEGER',
        );
      }
      if (!sessionExerciseColumns.any((c) => c['name'] == 'distance_km')) {
        await db.execute(
          'ALTER TABLE session_exercises ADD COLUMN distance_km REAL',
        );
      }
    }
    if (oldVersion < 14) {
      await _createCustomExercisesTable(db);
    }
    if (oldVersion < 15) {
      await _createMedalsTables(db);
    }
    if (oldVersion < 16) {
      final templateExerciseColumns =
          await db.rawQuery('PRAGMA table_info(template_exercises)');
      if (!templateExerciseColumns
          .any((c) => c['name'] == 'target_weight_kg')) {
        await db.execute(
          'ALTER TABLE template_exercises ADD COLUMN target_weight_kg REAL',
        );
      }
      if (!templateExerciseColumns.any((c) => c['name'] == 'unilateral')) {
        await db.execute(
          'ALTER TABLE template_exercises ADD COLUMN unilateral INTEGER NOT NULL DEFAULT 0',
        );
      }
    }
    if (oldVersion < 17) {
      await _createPersonalFoodsTable(db);
    }
    if (oldVersion < 18) {
      final foodEntryColumns =
          await db.rawQuery('PRAGMA table_info(food_entries)');
      for (final column in ['fiber_g', 'sugar_g', 'sodium_mg']) {
        if (!foodEntryColumns.any((c) => c['name'] == column)) {
          await db.execute('ALTER TABLE food_entries ADD COLUMN $column REAL');
        }
      }
      final comboColumns =
          await db.rawQuery('PRAGMA table_info(saved_food_combos)');
      for (final column in ['fiber_g', 'sugar_g', 'sodium_mg']) {
        if (!comboColumns.any((c) => c['name'] == column)) {
          await db
              .execute('ALTER TABLE saved_food_combos ADD COLUMN $column REAL');
        }
      }
    }
    if (oldVersion < 19) {
      final profileColumns = await db.rawQuery('PRAGMA table_info(profile)');
      final profileColumnNames = profileColumns.map((c) => c['name']).toSet();
      if (!profileColumnNames.contains('initial_activity_level')) {
        await db.execute(
            'ALTER TABLE profile ADD COLUMN initial_activity_level TEXT');
      }
      if (!profileColumnNames.contains('precise_calorie_tracking_enabled')) {
        await db.execute(
          'ALTER TABLE profile ADD COLUMN precise_calorie_tracking_enabled INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (!profileColumnNames.contains('job_activity_level')) {
        await db
            .execute('ALTER TABLE profile ADD COLUMN job_activity_level TEXT');
      }
      if (!profileColumnNames.contains('exercise_days_per_week')) {
        await db.execute(
            'ALTER TABLE profile ADD COLUMN exercise_days_per_week INTEGER');
      }
      if (!profileColumnNames.contains('exercise_intensity')) {
        await db
            .execute('ALTER TABLE profile ADD COLUMN exercise_intensity TEXT');
      }
      if (!profileColumnNames.contains('workout_nudge_dismissed')) {
        await db.execute(
          'ALTER TABLE profile ADD COLUMN workout_nudge_dismissed INTEGER NOT NULL DEFAULT 0',
        );
      }
    }
    if (oldVersion < 20) {
      await _createActiveWorkoutSnapshotTable(db);
    }
    if (oldVersion < 21) {
      await _createAppSettingsTable(db);
      final settingsColumns =
          await db.rawQuery('PRAGMA table_info(app_settings)');
      final settingsColumnNames = settingsColumns.map((c) => c['name']).toSet();
      if (!settingsColumnNames.contains('muscle_rank_enabled')) {
        await db.execute(
          'ALTER TABLE app_settings ADD COLUMN muscle_rank_enabled INTEGER NOT NULL DEFAULT 0',
        );
      }
    }
    if (oldVersion < 22) {
      final customExerciseColumns =
          await db.rawQuery('PRAGMA table_info(custom_exercises)');
      final hasTrackingType =
          customExerciseColumns.any((c) => c['name'] == 'tracking_type');
      if (!hasTrackingType) {
        await db.execute(
            'ALTER TABLE custom_exercises ADD COLUMN tracking_type TEXT');
      }
    }
    if (oldVersion < 23) {
      await _createScannedProductsTable(db);
    }
  }

  Future<void> _createScannedProductsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scanned_products (
        barcode TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        calories REAL,
        protein_g REAL,
        carbs_g REAL,
        fat_g REAL,
        fiber_g REAL,
        sugar_g REAL,
        sodium_mg REAL,
        serving_grams REAL,
        last_scanned_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createMedalsTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS unlocked_medals (
        id TEXT PRIMARY KEY,
        unlocked_at TEXT NOT NULL,
        viewed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS nutrition_goal_history (
        id TEXT PRIMARY KEY,
        mode TEXT NOT NULL,
        target_weight_kg REAL,
        started_at TEXT NOT NULL,
        ended_at TEXT
      )
    ''');
  }

  Future<void> _createCustomExercisesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        equipment TEXT NOT NULL,
        movement TEXT,
        unilateral INTEGER NOT NULL DEFAULT 0,
        video_url TEXT,
        tracking_type TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPersonalFoodsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS personal_foods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        calories_per_100g REAL NOT NULL,
        protein_per_100g REAL NOT NULL,
        carbs_per_100g REAL NOT NULL,
        fat_per_100g REAL NOT NULL,
        fiber_per_100g REAL,
        sugar_per_100g REAL,
        sodium_mg_per_100g REAL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Column name -> default value (minutes-since-midnight for `*_minutes`
  /// columns, 0/1 for `*_enabled` columns), shared between the v7/v8 upgrade
  /// blocks and [_createAppSettingsTable] so fresh installs and upgraded
  /// installs end up with the same schema.
  static const Map<String, int> _reminderColumnDefaults = {
    'breakfast_reminder_enabled': 0,
    'breakfast_reminder_minutes': 480, // 8:00 AM
    'lunch_reminder_enabled': 0,
    'lunch_reminder_minutes': 780, // 1:00 PM
    'dinner_reminder_enabled': 0,
    'dinner_reminder_minutes': 1140, // 7:00 PM
    'weighin_reminder_enabled': 0,
    'weighin_reminder_minutes': 480, // 8:00 AM
    'workout_reminder_enabled': 0,
    'workout_reminder_minutes': 1080, // 6:00 PM
    'backup_reminder_enabled': 0,
    'backup_reminder_minutes': 600, // 10:00 AM, Sundays
  };

  Future<void> _createAppSettingsTable(Database db) async {
    final reminderColumns = _reminderColumnDefaults.entries
        .map((e) => '${e.key} INTEGER NOT NULL DEFAULT ${e.value}')
        .join(',\n        ');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        theme_seed TEXT NOT NULL DEFAULT 'classic',
        theme_mode TEXT NOT NULL DEFAULT 'system',
        unit_system TEXT NOT NULL DEFAULT 'metric',
        $reminderColumns,
        health_sync_enabled INTEGER NOT NULL DEFAULT 0,
        app_lock_enabled INTEGER NOT NULL DEFAULT 0,
        cycle_tracking_enabled INTEGER NOT NULL DEFAULT 0,
        cycle_adjust_calories INTEGER NOT NULL DEFAULT 0,
        muscle_rank_enabled INTEGER NOT NULL DEFAULT 0,
        pin_hash TEXT,
        pin_salt TEXT
      )
    ''');
  }

  /// Single-row snapshot of the in-progress workout (if any), re-saved
  /// after every change so a crash or an unwanted app restart mid-workout
  /// loses at most the last few seconds of progress instead of the whole
  /// session — see `ActiveWorkoutRepository`.
  Future<void> _createActiveWorkoutSnapshotTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_workout_snapshot (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        data TEXT NOT NULL,
        saved_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createCycleTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cycle_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');
  }

  Future<void> _createFoodCombosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_food_combos (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        default_meal_type TEXT NOT NULL,
        ingredients_json TEXT,
        calories REAL NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        fiber_g REAL,
        sugar_g REAL,
        sodium_mg REAL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createNutritionTables(Database db) async {
    await _createFoodCombosTable(db);

    await db.execute('''
      CREATE TABLE supplements (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE nutrition_goal (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        mode TEXT NOT NULL,
        intensity TEXT NOT NULL,
        target_weight_kg REAL,
        custom_calorie_delta REAL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createWorkoutTables(Database db) async {
    await db.execute('''
      CREATE TABLE workout_split (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        day_names TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_templates (
        id TEXT PRIMARY KEY,
        day_name TEXT NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE template_exercises (
        id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        category TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        target_sets INTEGER NOT NULL,
        target_reps INTEGER NOT NULL,
        duration_seconds INTEGER,
        target_weight_kg REAL,
        unilateral INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (template_id) REFERENCES workout_templates (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY,
        template_id TEXT,
        day_name TEXT NOT NULL,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        duration_minutes INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE session_exercises (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        duration_seconds INTEGER,
        calories_burned INTEGER,
        distance_km REAL,
        FOREIGN KEY (session_id) REFERENCES workout_sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE session_sets (
        id TEXT PRIMARY KEY,
        session_exercise_id TEXT NOT NULL,
        set_index INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        reps INTEGER NOT NULL,
        side TEXT,
        FOREIGN KEY (session_exercise_id) REFERENCES session_exercises (id) ON DELETE CASCADE
      )
    ''');
  }
}
