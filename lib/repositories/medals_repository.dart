import 'package:flutter/foundation.dart';

import '../core/db/database_helper.dart';
import '../data/medal_catalog.dart';

class MedalsRepository extends ChangeNotifier {
  Map<String, DateTime> _unlockedAt = {};
  Set<String> _viewedIds = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  Set<String> get unlockedIds => _unlockedAt.keys.toSet();
  DateTime? unlockedAt(String id) => _unlockedAt[id];
  bool isUnlocked(String id) => _unlockedAt.containsKey(id);
  bool get hasUnviewed => _unlockedAt.keys.any((id) => !_viewedIds.contains(id));

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('unlocked_medals');
    _unlockedAt = {
      for (final row in rows) row['id'] as String: DateTime.parse(row['unlocked_at'] as String),
    };
    _viewedIds = {
      for (final row in rows)
        if ((row['viewed'] as num?) == 1) row['id'] as String,
    };
    _loaded = true;
    notifyListeners();
  }

  /// Diffs the catalog's current progress against what's already unlocked,
  /// persists any newly-crossed-1.0 medals, and returns just those — the
  /// caller (e.g. the post-workout summary screen) uses the return value to
  /// show an unlock banner without having to re-diff itself.
  Future<List<MedalDef>> evaluate(MedalContext ctx) async {
    final newly = <MedalDef>[];
    for (final medal in medalCatalog) {
      if (_unlockedAt.containsKey(medal.id)) continue;
      if (medal.progress(ctx) >= 1.0) newly.add(medal);
    }
    if (newly.isEmpty) return newly;

    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      for (final medal in newly) {
        await txn.insert('unlocked_medals', {
          'id': medal.id,
          'unlocked_at': now.toIso8601String(),
          'viewed': 0,
        });
      }
    });
    await load();
    return newly;
  }

  /// Inverse of [evaluate] — re-checks every currently-unlocked medal
  /// against current data and removes any whose progress has fallen back
  /// below 1.0. Call this after deleting a workout, exercise, or food
  /// entry, since that can retroactively undo what had earned a medal
  /// (e.g. a test workout logged by mistake). Returns the medals that got
  /// re-locked so the caller can tell the user what disappeared.
  Future<List<MedalDef>> reconcile(MedalContext ctx) async {
    final relocked = <MedalDef>[];
    for (final id in _unlockedAt.keys) {
      MedalDef? medal;
      for (final candidate in medalCatalog) {
        if (candidate.id == id) {
          medal = candidate;
          break;
        }
      }
      if (medal != null && medal.progress(ctx) < 1.0) relocked.add(medal);
    }
    if (relocked.isEmpty) return relocked;

    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      for (final medal in relocked) {
        await txn.delete('unlocked_medals', where: 'id = ?', whereArgs: [medal.id]);
      }
    });
    await load();
    return relocked;
  }

  Future<void> markAllViewed() async {
    if (!hasUnviewed) return;
    final db = await DatabaseHelper.instance.database;
    await db.update('unlocked_medals', {'viewed': 1});
    await load();
  }
}
