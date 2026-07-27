import 'package:flutter/material.dart';

/// A -/value/+ control used anywhere a number (weight, reps, sets, duration,
/// calories, distance) needs incrementing — the active workout screen, the
/// workout baseline screen, and the logged-session editor all share this
/// exact widget rather than each rolling their own. Tapping the value itself
/// (when [onTapValue] is set) opens a numeric keyboard via
/// `showNumericInputDialog` for typing a value directly instead of tapping
/// +/- repeatedly.
class NumericStepper extends StatelessWidget {
  final String label;
  final String semanticName;
  final String value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback? onTapValue;

  const NumericStepper({
    super.key,
    required this.label,
    required this.semanticName,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.onTapValue,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NumericStepperButton(
            icon: Icons.remove,
            onTap: onDecrement,
            semanticLabel: 'Decrease $semanticName',
          ),
          Expanded(
            child: InkWell(
              onTap: onTapValue,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _NumericStepperButton(
            icon: Icons.add,
            onTap: onIncrement,
            semanticLabel: 'Increase $semanticName',
          ),
        ],
      ),
    );
  }
}

class _NumericStepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  const _NumericStepperButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Semantics(
          button: true,
          label: semanticLabel,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: Icon(icon, size: 18)),
          ),
        ),
      ),
    );
  }
}
