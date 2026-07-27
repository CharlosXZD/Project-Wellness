import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/medal_catalog.dart';
import '../../repositories/medals_repository.dart';
import '../../repositories/nutrition_repository.dart';
import '../../repositories/training_repository.dart';

class MedalsScreen extends StatefulWidget {
  const MedalsScreen({super.key});

  @override
  State<MedalsScreen> createState() => _MedalsScreenState();
}

class _MedalsScreenState extends State<MedalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedalsRepository>().markAllViewed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final training = context.watch<TrainingRepository>();
    final nutrition = context.watch<NutritionRepository>();
    final medals = context.watch<MedalsRepository>();

    final ctx = MedalContext(
      sessions: training.sessions,
      weightEntries: training.weightEntries,
      goalHistory: nutrition.goalHistory,
      nutritionEntries: nutrition.entries,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Medals')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            for (final category in MedalCategory.values) ...[
              Text(_categoryLabel(category),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final medal
                  in medalCatalog.where((m) => m.category == category))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MedalTile(
                    medal: medal,
                    progress: medal.progress(ctx),
                    unlocked: medals.isUnlocked(medal.id),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  String _categoryLabel(MedalCategory category) {
    switch (category) {
      case MedalCategory.training:
        return 'Training';
      case MedalCategory.cardio:
        return 'Cardio';
      case MedalCategory.nutrition:
        return 'Nutrition';
      case MedalCategory.consistency:
        return 'Consistency';
    }
  }
}

/// Fixed rarity colors, same idea as real bronze/silver/gold medals — kept
/// constant across light/dark theme so tier reads consistently rather than
/// blending into whatever the current color scheme happens to be.
const _tierColors = {
  MedalTier.bronze: Color(0xFFB08D57),
  MedalTier.silver: Color(0xFFB0BEC5),
  MedalTier.gold: Color(0xFFFFC107),
  MedalTier.platinum: Color(0xFF7C4DFF),
};

const _tierLabels = {
  MedalTier.bronze: 'BRONZE',
  MedalTier.silver: 'SILVER',
  MedalTier.gold: 'GOLD',
  MedalTier.platinum: 'PLATINUM',
};

class _MedalTile extends StatelessWidget {
  final MedalDef medal;
  final double progress;
  final bool unlocked;

  const _MedalTile(
      {required this.medal, required this.progress, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = progress.clamp(0.0, 1.0);
    final tierColor = _tierColors[medal.tier]!;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: unlocked ? tierColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: tierColor, width: 2),
              ),
              child: Icon(
                medal.icon,
                color: unlocked ? Colors.white : tierColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(medal.title,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Text(
                        _tierLabels[medal.tier]!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: tierColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    medal.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  if (!unlocked) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: clamped,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(clamped * 100).round()}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
