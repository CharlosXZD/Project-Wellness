import 'package:flutter/material.dart';

/// "+ Create new personal food" row, styled identically to a regular food
/// row (see `food_picker_screen.dart`) so it fits right in at the top of
/// the list rather than looking like a separate control.
class CreateFoodCard extends StatelessWidget {
  final VoidCallback onTap;

  const CreateFoodCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, size: 26, color: scheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Create new personal food',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
