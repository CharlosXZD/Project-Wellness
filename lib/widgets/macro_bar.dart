import 'package:flutter/material.dart';

/// Shared protein/carbs/fat colors so the summary card, history chart, and
/// any future screen all agree on which color means which macro.
class MacroColors {
  static const protein = Color(0xFF3E7C6B);
  static const carbs = Color(0xFFE0A458);
  static const fat = Color(0xFFB5555A);
}

/// Stacked protein/carbs/fat bar, used under a calorie total.
class MacroBar extends StatelessWidget {
  final double proteinG;
  final double carbsG;
  final double fatG;

  const MacroBar({
    super.key,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  @override
  Widget build(BuildContext context) {
    final macroTotal = proteinG + carbsG + fatG;
    if (macroTotal <= 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            _MacroBarSegment(flex: proteinG, color: MacroColors.protein),
            _MacroBarSegment(flex: carbsG, color: MacroColors.carbs),
            _MacroBarSegment(flex: fatG, color: MacroColors.fat),
          ],
        ),
      ),
    );
  }
}

class _MacroBarSegment extends StatelessWidget {
  final double flex;
  final Color color;

  const _MacroBarSegment({required this.flex, required this.color});

  @override
  Widget build(BuildContext context) {
    final safeFlex = flex <= 0 ? 0.001 : flex;
    return Expanded(
      flex: (safeFlex * 100).round(),
      child: Container(color: color),
    );
  }
}

/// Row of protein/carbs/fat legend entries with grams, shown under a
/// [MacroBar].
class MacroLegendRow extends StatelessWidget {
  final double proteinG;
  final double carbsG;
  final double fatG;

  const MacroLegendRow({
    super.key,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MacroLegend(label: 'Protein', grams: proteinG, color: MacroColors.protein),
        MacroLegend(label: 'Carbs', grams: carbsG, color: MacroColors.carbs),
        MacroLegend(label: 'Fat', grams: fatG, color: MacroColors.fat),
      ],
    );
  }
}

class MacroLegend extends StatelessWidget {
  final String label;
  final double grams;
  final Color color;

  const MacroLegend({
    super.key,
    required this.label,
    required this.grams,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${grams.toStringAsFixed(0)} g',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
