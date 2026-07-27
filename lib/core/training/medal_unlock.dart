import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/medal_catalog.dart';
import '../../repositories/medals_repository.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/training_repository.dart';
import '../notifications/notification_service.dart';

MedalContext _currentMedalContext(BuildContext context) {
  final trainingRepo = context.read<TrainingRepository>();
  final nutritionRepo = context.read<NutritionRepository>();
  return MedalContext(
    sessions: trainingRepo.sessions,
    weightEntries: trainingRepo.weightEntries,
    goalHistory: nutritionRepo.goalHistory,
    nutritionEntries: nutritionRepo.entries,
  );
}

/// Re-checks the medal catalog against current data and, if anything newly
/// crossed 1.0, shows the unlock SnackBar and fires the instant push
/// notification. Shared by every place that logs something the catalog can
/// react to (weigh-ins, food entries) — the post-workout flow has its own
/// richer in-screen banner instead, but calls the same underlying
/// `MedalsRepository.evaluate` and `NotificationService.notifyMedalUnlocked`.
Future<void> evaluateMedalsAndNotify(BuildContext context) async {
  final newlyUnlocked =
      await context.read<MedalsRepository>().evaluate(_currentMedalContext(context));
  if (newlyUnlocked.isEmpty) return;

  for (final medal in newlyUnlocked) {
    unawaited(NotificationService.instance.notifyMedalUnlocked(medal.title));
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Medal unlocked: ${newlyUnlocked.first.title}')),
  );
}

/// Inverse of [evaluateMedalsAndNotify] — call after deleting a workout,
/// exercise, or food entry, in case that deletion dropped a medal's
/// progress back below 1.0 (e.g. a test workout that shouldn't have
/// counted). Just a plain SnackBar, no push notification — losing a medal
/// isn't the kind of thing worth a background alert.
Future<void> reconcileMedalsAfterDeletion(BuildContext context) async {
  final relocked =
      await context.read<MedalsRepository>().reconcile(_currentMedalContext(context));
  if (relocked.isEmpty || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Medal removed: ${relocked.first.title} (no longer earned)')),
  );
}
