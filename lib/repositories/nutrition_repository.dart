import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/db/database_helper.dart';
import '../core/sharing/library_share.dart';
import '../models/food_entry.dart';
import '../models/nutrition_goal.dart';
import '../models/personal_food.dart';
import '../models/saved_food_combo.dart';
import '../models/scanned_product.dart';
import '../models/supplement.dart';

class MacroTotals {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const MacroTotals({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });
}

class DailyTotal {
  final DateTime date;
  final MacroTotals totals;

  const DailyTotal({required this.date, required this.totals});
}

class NutritionRepository extends ChangeNotifier {
  List<FoodEntry> _entries = [];
  List<SavedFoodCombo> _combos = [];
  List<Supplement> _supplements = [];
  List<PersonalFood> _personalFoods = [];
  List<ScannedProduct> _scannedProducts = [];
  NutritionGoal? _goal;
  List<GoalHistoryEntry> _goalHistory = [];
  bool _loaded = false;

  List<FoodEntry> get entries => _entries;

  /// All saved combos (snacks and meals together) — see [snacks] and
  /// [meals] for the filtered lists each screen actually displays.
  List<SavedFoodCombo> get combos => _combos;
  List<SavedFoodCombo> get snacks =>
      _combos.where((c) => c.defaultMealType == MealType.snack).toList();
  List<SavedFoodCombo> get meals =>
      _combos.where((c) => c.defaultMealType != MealType.snack).toList();

  List<Supplement> get supplements => _supplements;
  List<PersonalFood> get personalFoods => _personalFoods;

  /// Newest first — cached barcode lookups, so "Previously scanned" can
  /// re-log or save one without a fresh network round-trip.
  List<ScannedProduct> get scannedProducts => _scannedProducts;
  NutritionGoal? get goal => _goal;
  List<GoalHistoryEntry> get goalHistory => _goalHistory;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;

    final rows = await db.query('food_entries', orderBy: 'date DESC');
    _entries = rows.map(FoodEntry.fromMap).toList();

    final comboRows =
        await db.query('saved_food_combos', orderBy: 'created_at ASC');
    _combos = comboRows.map(SavedFoodCombo.fromMap).toList();

    final supplementRows =
        await db.query('supplements', orderBy: 'created_at ASC');
    _supplements = supplementRows.map(Supplement.fromMap).toList();

    final personalFoodRows =
        await db.query('personal_foods', orderBy: 'created_at ASC');
    _personalFoods = personalFoodRows.map(PersonalFood.fromMap).toList();

    final scannedProductRows =
        await db.query('scanned_products', orderBy: 'last_scanned_at DESC');
    _scannedProducts = scannedProductRows.map(ScannedProduct.fromMap).toList();

    final goalRows =
        await db.query('nutrition_goal', where: 'id = 1', limit: 1);
    _goal = goalRows.isEmpty ? null : NutritionGoal.fromMap(goalRows.first);

    final goalHistoryRows =
        await db.query('nutrition_goal_history', orderBy: 'started_at ASC');
    _goalHistory = goalHistoryRows.map(GoalHistoryEntry.fromMap).toList();

    _loaded = true;
    notifyListeners();
  }

  Future<void> addEntry(FoodEntry entry) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('food_entries', entry.toMap());
    await load();
  }

  Future<void> updateEntry(FoodEntry entry) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'food_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    await load();
  }

  Future<void> deleteEntry(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('food_entries', where: 'id = ?', whereArgs: [id]);
    await load();
  }

  List<FoodEntry> entriesForDate(DateTime date) {
    return _entries.where((e) => _isSameDay(e.date, date)).toList();
  }

  MacroTotals totalsForDate(DateTime date) {
    final dayEntries = entriesForDate(date);
    return MacroTotals(
      calories: dayEntries.fold(0, (sum, e) => sum + e.calories),
      proteinG: dayEntries.fold(0, (sum, e) => sum + e.proteinG),
      carbsG: dayEntries.fold(0, (sum, e) => sum + e.carbsG),
      fatG: dayEntries.fold(0, (sum, e) => sum + e.fatG),
    );
  }

  /// One [DailyTotal] per calendar day from [start] to [end] inclusive,
  /// zero-filled on days with no logged food.
  List<DailyTotal> dailyTotalsForRange(DateTime start, DateTime end) {
    final days = <DailyTotal>[];
    var cursor = DateTime(start.year, start.month, start.day);
    final lastDay = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(lastDay)) {
      days.add(DailyTotal(date: cursor, totals: totalsForDate(cursor)));
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  Future<void> addCombo(SavedFoodCombo combo) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('saved_food_combos', combo.toMap());
    await load();
  }

  Future<void> updateCombo(SavedFoodCombo combo) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'saved_food_combos',
      combo.toMap(),
      where: 'id = ?',
      whereArgs: [combo.id],
    );
    await load();
  }

  Future<void> deleteCombo(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('saved_food_combos', where: 'id = ?', whereArgs: [id]);
    await load();
  }

  Future<void> createPersonalFood(PersonalFood food) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('personal_foods', food.toMap());
    await load();
  }

  Future<void> updatePersonalFood(PersonalFood food) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'personal_foods',
      food.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
    await load();
  }

  Future<void> deletePersonalFood(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('personal_foods', where: 'id = ?', whereArgs: [id]);
    await load();
  }

  /// Caches a barcode lookup so it's re-logged instantly next time instead
  /// of hitting the network again. Keyed by barcode — scanning the same
  /// product again replaces this row (fresh `lastScannedAt`, same barcode)
  /// rather than adding a second entry, which is what keeps a double-scan
  /// from showing up twice in "Previously scanned".
  Future<void> upsertScannedProduct(ScannedProduct product) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'scanned_products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await load();
  }

  Future<void> deleteScannedProduct(String barcode) async {
    final db = await DatabaseHelper.instance.database;
    await db
        .delete('scanned_products', where: 'barcode = ?', whereArgs: [barcode]);
    await load();
  }

  /// Adds every food in [incoming] that isn't already in this user's
  /// library (matched by name, case-insensitive) — additive only, never
  /// overwrites or removes an existing food, matching the "fresh IDs,
  /// additive" rule every other import in docs/SHARING_SYSTEM.md follows.
  /// Returns how many were actually added.
  Future<int> mergePersonalFoods(List<PersonalFood> incoming) async {
    final toAdd = newItemsByName(
      incoming: incoming,
      existingNames: _personalFoods.map((f) => f.name),
      nameOf: (f) => f.name,
    );
    if (toAdd.isEmpty) return 0;

    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      for (final food in toAdd) {
        await txn.insert('personal_foods', food.toMap());
      }
    });
    await load();
    return toAdd.length;
  }

  Future<void> addSupplement(Supplement supplement) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('supplements', supplement.toMap());
    await load();
  }

  Future<void> deleteSupplement(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('supplements', where: 'id = ?', whereArgs: [id]);
    await load();
  }

  /// Saves the current goal and appends it to the goal history log (used by
  /// the medals system to detect "completed a cut/bulk" — see
  /// [GoalHistoryEntry]). Skips opening a new history row when [goal] hasn't
  /// actually changed mode/target from the previous save, so re-saving the
  /// same goal (e.g. tweaking intensity) doesn't fragment one cut into many
  /// history rows.
  Future<void> saveGoal(NutritionGoal goal) async {
    final db = await DatabaseHelper.instance.database;
    final previous = _goal;
    final isNewGoal = previous == null ||
        previous.mode != goal.mode ||
        previous.targetWeightKg != goal.targetWeightKg;

    await db.transaction((txn) async {
      await txn.insert(
        'nutrition_goal',
        goal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (isNewGoal) {
        if (_goalHistory.isNotEmpty && _goalHistory.last.endedAt == null) {
          await txn.update(
            'nutrition_goal_history',
            {'ended_at': goal.updatedAt.toIso8601String()},
            where: 'id = ?',
            whereArgs: [_goalHistory.last.id],
          );
        }
        await txn.insert(
          'nutrition_goal_history',
          GoalHistoryEntry(
            id: const Uuid().v4(),
            mode: goal.mode,
            targetWeightKg: goal.targetWeightKg,
            startedAt: goal.updatedAt,
          ).toMap(),
        );
      }
    });

    await load();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
