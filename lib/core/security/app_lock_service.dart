import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Bridges to the device's own biometric/passcode authentication via
/// `package:local_auth` — Face ID/Touch ID/fingerprint, with automatic
/// fallback to the device passcode/PIN/pattern when biometrics aren't
/// enrolled. Also holds the (stateless) hashing logic for the in-app 4-digit
/// PIN fallback — the actual hash/salt persistence lives in
/// `SettingsRepository`, same split as `HealthService`'s sync flag.
/// Nothing here talks to a server; it's purely local.
class AppLockService {
  AppLockService._();

  static final AppLockService instance = AppLockService._();

  final _auth = LocalAuthentication();

  /// A fresh random salt for a new PIN — call once when the user sets one.
  String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  /// Compares [pin] against the stored [hash]/[salt] — never store or
  /// compare the raw PIN.
  bool verifyPin(String pin, {required String hash, required String salt}) {
    return hashPin(pin, salt) == hash;
  }

  /// Whether this device can do any local authentication at all (biometric
  /// or device credential). Check before letting the user enable app lock.
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('AppLockService: isDeviceSupported check failed: $e');
      return false;
    }
  }

  /// Prompts Face ID/Touch ID/fingerprint, falling back to the device
  /// passcode/PIN/pattern. Returns whether it succeeded — a declined or
  /// failed prompt is a normal outcome, not something to crash on.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Project Wellness',
      );
    } catch (e) {
      debugPrint('AppLockService: authentication failed: $e');
      return false;
    }
  }
}
