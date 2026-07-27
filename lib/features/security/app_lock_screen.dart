import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/security/app_lock_service.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/settings_repository.dart';
import '../../widgets/pin_keypad.dart';
import '../../widgets/pw_logo.dart';

/// Shown by `_AppLockGate` (in `lib/app.dart`) instead of the app's real
/// content whenever app lock is enabled and the app hasn't been unlocked yet
/// this session — on cold start, and every time it resumes from background.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _authenticating = false;
  bool _showPinEntry = false;
  String? _pinError;
  final _keypadKey = GlobalKey<PinKeypadState>();

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final success = await AppLockService.instance.authenticate();
    if (!mounted) return;
    setState(() => _authenticating = false);
    if (success) {
      widget.onUnlocked();
    }
  }

  void _handlePinComplete(String pin) {
    final settings = context.read<SettingsRepository>();
    final hash = settings.pinHash;
    final salt = settings.pinSalt;
    if (hash == null || salt == null) return;

    final valid = AppLockService.instance.verifyPin(pin, hash: hash, salt: salt);
    if (valid) {
      widget.onUnlocked();
    } else {
      setState(() => _pinError = 'Incorrect PIN');
      _keypadKey.currentState?.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    // Prompt immediately so the user isn't stuck staring at a button they
    // have to tap first every single time.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // Always offered when a PIN is set, not just after a failed biometric
    // attempt — simpler than trying to detect every "biometric unavailable"
    // case precisely.
    final hasPin = context.watch<SettingsRepository>().pinHash != null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ThemedPwLogo(),
                const SizedBox(height: 24),
                Text(
                  l10n.appLockedTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (!_showPinEntry) ...[
                  FilledButton.icon(
                    onPressed: _authenticating ? null : _unlock,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(_authenticating ? l10n.unlocking : l10n.unlock),
                  ),
                  if (hasPin) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() {
                        _showPinEntry = true;
                        _pinError = null;
                      }),
                      child: const Text('Use PIN instead'),
                    ),
                  ],
                ] else ...[
                  if (_pinError != null) ...[
                    Text(_pinError!, style: TextStyle(color: scheme.error)),
                    const SizedBox(height: 12),
                  ],
                  PinKeypad(key: _keypadKey, onComplete: _handlePinComplete),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _showPinEntry = false),
                    child: const Text('Use biometric instead'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      backgroundColor: scheme.surface,
    );
  }
}
