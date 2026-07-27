import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Prompts for a single number via a real keyboard instead of tapping a
/// stepper button repeatedly — used by the active-workout weight/reps
/// steppers so a big jump (e.g. typing "225" for a heavy set) doesn't take
/// dozens of taps. Returns null if the user cancels or clears the field.
Future<double?> showNumericInputDialog(
  BuildContext context, {
  required String title,
  required double initialValue,
  bool allowDecimal = true,
}) {
  // Never fall back to the raw `toString()` of a double — repeated +/-
  // taps can leave a value a hair off a whole number (e.g. 5.000000004
  // from floating-point drift), and `toString()` would show every noisy
  // digit instead of the clean value the user actually expects to see.
  final rounded = double.parse(initialValue.toStringAsFixed(allowDecimal ? 1 : 0));
  final controller = TextEditingController(
    text: rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1),
  );

  return showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        inputFormatters: [
          if (allowDecimal)
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))
          else
            FilteringTextInputFormatter.digitsOnly,
        ],
        onSubmitted: (value) {
          final parsed = double.tryParse(value);
          Navigator.of(context).pop(parsed);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final parsed = double.tryParse(controller.text);
            Navigator.of(context).pop(parsed);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
