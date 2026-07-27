import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/security/app_lock_service.dart';
import '../../repositories/settings_repository.dart';
import '../../widgets/pin_keypad.dart';

/// Two-step PIN setup: enter, then confirm. Reached from Settings once
/// biometric app lock is on — the PIN is a fallback for when biometric
/// fails, not a mode picked instead of it.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _keypadKey = GlobalKey<PinKeypadState>();
  String? _firstEntry;
  String? _error;

  Future<void> _handleComplete(String pin) async {
    if (_firstEntry == null) {
      setState(() {
        _firstEntry = pin;
        _error = null;
      });
      _keypadKey.currentState?.clear();
      return;
    }

    if (pin != _firstEntry) {
      setState(() {
        _firstEntry = null;
        _error = "PINs didn't match — try again";
      });
      _keypadKey.currentState?.clear();
      return;
    }

    final salt = AppLockService.instance.generateSalt();
    final hash = AppLockService.instance.hashPin(pin, salt);
    await context.read<SettingsRepository>().setPin(hash, salt);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isConfirmStep = _firstEntry != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Set up PIN backup')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isConfirmStep ? 'Confirm your PIN' : 'Enter a 4-digit PIN',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Used as a backup on the lock screen if biometric unlock fails.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
              const SizedBox(height: 32),
              PinKeypad(key: _keypadKey, onComplete: _handleComplete),
            ],
          ),
        ),
      ),
    );
  }
}
