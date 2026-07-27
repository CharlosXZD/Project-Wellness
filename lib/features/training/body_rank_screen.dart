import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/muscle_regions.dart';
import '../../models/user_profile.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/muscle_body_diagram.dart';

class BodyRankScreen extends StatefulWidget {
  const BodyRankScreen({super.key});

  @override
  State<BodyRankScreen> createState() => _BodyRankScreenState();
}

class _BodyRankScreenState extends State<BodyRankScreen> {
  MuscleRegion? _selectedRegion;

  void _toggleRegion(MuscleRegion? region) {
    setState(() => _selectedRegion = region == _selectedRegion ? null : region);
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<TrainingRepository>().sessions;
    final ranks = {
      for (final region in MuscleRegion.values)
        region: rankFor(region, sessions),
    };
    final overall = overallRank(sessions);
    final sex = context.watch<ProfileRepository>().profile?.sex ?? Sex.male;
    final selectedRegion = _selectedRegion;

    return Scaffold(
      appBar: AppBar(title: const Text('Body Rank')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _OverallRankTile(tier: overall),
            const SizedBox(height: 20),
            MuscleBodyDiagram(
              ranks: ranks.map((region, rank) => MapEntry(region, rank.tier)),
              sex: sex,
              selectedRegion: selectedRegion,
              onRegionTap: _toggleRegion,
            ),
            if (selectedRegion != null) ...[
              const SizedBox(height: 16),
              _RegionExercisesCard(
                region: selectedRegion,
                onClose: () => _toggleRegion(null),
              ),
            ],
            const SizedBox(height: 24),
            Text('Muscle Rankings',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final region in MuscleRegion.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MuscleRegionTile(
                  region: region,
                  rank: ranks[region]!,
                  selected: region == selectedRegion,
                  onTap: () => _toggleRegion(region),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverallRankTile extends StatelessWidget {
  final MuscleRankTier tier;

  const _OverallRankTile({required this.tier});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration:
                  BoxDecoration(color: tier.color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  tier.code,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tier.onColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Rank',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                Text(tier.displayName,
                    style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionExercisesCard extends StatelessWidget {
  final MuscleRegion region;
  final VoidCallback onClose;

  const _RegionExercisesCard({required this.region, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final exercises = exerciseNamesForRegion(region);

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${region.label} exercises',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 20),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Close',
                ),
              ],
            ),
            if (exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 8, 4),
                child: Text(
                  'No exercises mapped to this muscle yet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in exercises)
                    Chip(
                      label: Text(name),
                      backgroundColor: scheme.surfaceContainerHighest,
                      side: BorderSide.none,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MuscleRegionTile extends StatelessWidget {
  final MuscleRegion region;
  final MuscleRank rank;
  final bool selected;
  final VoidCallback onTap;

  const _MuscleRegionTile({
    required this.region,
    required this.rank,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                selected ? Border.all(color: scheme.primary, width: 2) : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: rank.tier.color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    rank.tier.code,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: rank.tier.onColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(region.label,
                              style: Theme.of(context).textTheme.titleSmall),
                        ),
                        Text(
                          rank.tier.displayName,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: rank.progress,
                        minHeight: 5,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(rank.tier.color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
