import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../core/db/database_helper.dart';
import '../models/user_profile.dart';

class ProfileRepository extends ChangeNotifier {
  UserProfile? _profile;
  bool _loaded = false;

  UserProfile? get profile => _profile;
  bool get hasProfile => _profile != null;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('profile', where: 'id = 1', limit: 1);
    _profile = rows.isEmpty ? null : UserProfile.fromMap(rows.first);
    _loaded = true;
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _profile = profile;
    notifyListeners();
  }

  Future<void> updateSex(Sex sex) async {
    final current = _profile;
    if (current == null) return;
    await saveProfile(current.copyWith(sex: sex));
  }
}
