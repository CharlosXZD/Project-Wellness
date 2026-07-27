import 'package:flutter/foundation.dart';

import '../core/db/database_helper.dart';
import '../models/cycle_entry.dart';

/// Logged period-start dates, entirely separate from [ProfileRepository]'s
/// `Sex` field — this is an opt-in feature anyone can enable in Settings,
/// not something gated behind a gender selection.
class CycleRepository extends ChangeNotifier {
  List<CycleEntry> _entries = [];
  bool _loaded = false;

  List<CycleEntry> get entries => _entries;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('cycle_entries', orderBy: 'date DESC');
    _entries = rows.map(CycleEntry.fromMap).toList();
    _loaded = true;
    notifyListeners();
  }

  Future<void> addEntry(CycleEntry entry) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('cycle_entries', entry.toMap());
    await load();
  }

  Future<void> deleteEntry(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('cycle_entries', where: 'id = ?', whereArgs: [id]);
    await load();
  }
}
