import 'package:flutter/foundation.dart';

import '../core/health/health_service.dart';

/// Cached Apple Health / Health Connect activity averages, so every screen
/// that shows a calorie target reads the *same* numbers synchronously
/// instead of each one querying Health on its own (which is how the Goals
/// screen and the Nutrition "Today" card used to end up with different
/// targets).
class HealthActivityRepository extends ChangeNotifier {
  static const _staleAfter = Duration(minutes: 30);

  HealthActivitySummary? _summary;
  DateTime? _fetchedAt;
  bool _fetching = false;

  HealthActivitySummary? get summary => _summary;

  /// Refreshes from Health when sync is on and the cache is stale; clears it
  /// when sync is off. Safe to call on every build — it no-ops otherwise.
  Future<void> refreshIfNeeded({required bool syncEnabled}) async {
    // Callers invoke this from build(); never notify synchronously there.
    await Future<void>.value();
    if (!syncEnabled) {
      if (_summary != null) {
        _summary = null;
        _fetchedAt = null;
        notifyListeners();
      }
      return;
    }
    final fetchedAt = _fetchedAt;
    if (_fetching || (fetchedAt != null && DateTime.now().difference(fetchedAt) < _staleAfter)) {
      return;
    }
    _fetching = true;
    try {
      _summary = await HealthService.instance.averageDailyActivity();
      _fetchedAt = DateTime.now();
      notifyListeners();
    } finally {
      _fetching = false;
    }
  }
}
