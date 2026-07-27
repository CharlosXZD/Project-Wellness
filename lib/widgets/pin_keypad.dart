import 'package:flutter/material.dart';

/// Reusable numeric keypad for the 4-digit PIN feature — used both to set a
/// PIN (called twice: enter, then confirm) and to enter one to unlock.
/// Calls [onComplete] once [length] digits have been entered; the caller
/// decides what that means (compare to a confirmation, verify a hash, etc.)
/// and can call [PinKeypadState.clear] via a `GlobalKey` to reset the dots
/// after a mismatch.
class PinKeypad extends StatefulWidget {
  final ValueChanged<String> onComplete;
  final int length;

  const PinKeypad({super.key, required this.onComplete, this.length = 4});

  @override
  State<PinKeypad> createState() => PinKeypadState();
}

class PinKeypadState extends State<PinKeypad> {
  String _entered = '';

  void clear() => setState(() => _entered = '');

  void _tapDigit(String digit) {
    if (_entered.length >= widget.length) return;
    setState(() => _entered += digit);
    if (_entered.length == widget.length) {
      final pin = _entered;
      widget.onComplete(pin);
    }
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _entered.length ? scheme.primary : scheme.surfaceContainerHighest,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 260,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                _KeypadButton(label: d, onTap: () => _tapDigit(d)),
              const SizedBox.shrink(),
              _KeypadButton(label: '0', onTap: () => _tapDigit('0')),
              _KeypadButton(
                icon: Icons.backspace_outlined,
                onTap: _backspace,
                semanticLabel: 'Backspace',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  const _KeypadButton({this.label, this.icon, required this.onTap, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Semantics(
            button: true,
            label: semanticLabel ?? label,
            child: Center(
              child: label != null
                  ? Text(label!, style: Theme.of(context).textTheme.headlineSmall)
                  : Icon(icon, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
