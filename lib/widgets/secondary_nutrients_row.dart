import 'package:flutter/material.dart';

/// Small muted row for fiber/sugar/sodium — secondary to the main
/// calorie/protein/carb/fat numbers, shown only for the nutrients that are
/// actually known (all three are optional almost everywhere they're
/// tracked). Renders nothing if none are known.
class SecondaryNutrientsRow extends StatelessWidget {
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;

  const SecondaryNutrientsRow({
    super.key,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (fiberG != null) 'Fiber ${fiberG!.toStringAsFixed(0)}g',
      if (sugarG != null) 'Sugar ${sugarG!.toStringAsFixed(0)}g',
      if (sodiumMg != null) 'Sodium ${sodiumMg!.toStringAsFixed(0)}mg',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' · '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
