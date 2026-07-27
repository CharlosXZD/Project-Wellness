import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import 'share_codec.dart';

/// Tables in an order safe for both delete (reversed, children before
/// parents) and insert (as listed, parents before children).
const _tableOrder = [
  'profile',
  'workout_split',
  'workout_templates',
  'template_exercises',
  'workout_sessions',
  'session_exercises',
  'session_sets',
  'weight_entries',
  'food_entries',
  'saved_food_combos',
  'personal_foods',
  'scanned_products',
  'supplements',
  'nutrition_goal',
  'nutrition_goal_history',
  'cycle_entries',
  'custom_exercises',
  'unlocked_medals',
];

/// Dumps every local table into one opaque, compact text blob suitable for
/// writing to a `.txt` file and restoring later — the app's whole local
/// state, no cloud involved.
Future<String> exportBackup() async {
  final db = await DatabaseHelper.instance.database;
  final tables = <String, List<Map<String, Object?>>>{};
  for (final table in _tableOrder) {
    tables[table] = await db.query(table);
  }
  return encodePayload({'tables': tables}, SharePrefix.fullBackup);
}

/// Restores a backup produced by [exportBackup], replacing all current
/// local data. Runs as a single transaction so a failure midway rolls back
/// instead of leaving a half-restored database.
Future<void> importBackup(String content) async {
  final decoded = decodePayload(content);
  if (decoded.prefix != SharePrefix.fullBackup) {
    throw const ShareCodeException(
        'That file is not a Project Wellness backup.');
  }

  final tables = decoded.json['tables'] as Map<String, dynamic>;
  final db = await DatabaseHelper.instance.database;

  await db.transaction((txn) async {
    for (final table in _tableOrder.reversed) {
      await txn.delete(table);
    }
    for (final table in _tableOrder) {
      final rows = (tables[table] as List?) ?? const [];
      for (final row in rows) {
        await txn.insert(
          table,
          (row as Map<String, dynamic>).cast<String, Object?>(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  });
}

/// Wipes every row from every table in [_tableOrder] — profile, workouts,
/// nutrition, weight history, everything — leaving the schema (and the
/// device-local theme preference in `app_settings`, which isn't part of
/// this list) intact. There's no undo short of restoring a prior export;
/// callers must confirm with the user before calling this.
Future<void> deleteAllData() async {
  final db = await DatabaseHelper.instance.database;
  await db.transaction((txn) async {
    for (final table in _tableOrder.reversed) {
      await txn.delete(table);
    }
  });
}
