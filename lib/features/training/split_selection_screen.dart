import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/workout_split.dart';
import '../../repositories/training_repository.dart';
import '../../widgets/rect_button.dart';
import 'custom_split_screen.dart';

class SplitSelectionScreen extends StatelessWidget {
  const SplitSelectionScreen({super.key});

  static const _presets = [
    SplitType.pushPullLegs,
    SplitType.upperLower,
    SplitType.fullBody,
    SplitType.broSplit,
    SplitType.pilates,
  ];

  static const _icons = {
    SplitType.pushPullLegs: Icons.swap_vert,
    SplitType.upperLower: Icons.vertical_split,
    SplitType.fullBody: Icons.accessibility_new,
    SplitType.broSplit: Icons.view_week,
    SplitType.pilates: Icons.self_improvement,
  };

  Future<void> _choosePreset(BuildContext context, SplitType type) async {
    final split = WorkoutSplit(
      type: type,
      name: type.label,
      dayNames: type.defaultDayNames,
      createdAt: DateTime.now(),
    );
    await context.read<TrainingRepository>().saveSplit(split);
    if (context.mounted) {
      Navigator.of(context).popUntil(
        (route) => route.settings.name == 'training' || route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your split')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'How do you train?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              "This decides which day options you'll see when logging a workout. You can change it later.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            for (final type in _presets)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RectButton(
                  icon: _icons[type]!,
                  title: type.label,
                  subtitle: type.defaultDayNames.join(' · '),
                  onTap: () => _choosePreset(context, type),
                ),
              ),
            const SizedBox(height: 8),
            RectButton(
              icon: Icons.add_circle_outline,
              title: 'Add custom split',
              subtitle: 'Name your own days',
              outlined: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomSplitScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
