import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Switches the home-screen app icon to match the selected [AppThemeSeed].
///
/// iOS: calls `UIApplication.setAlternateIconName`.
/// Android: enables the matching `activity-alias` and disables the rest via
/// `PackageManager.setComponentEnabledSetting`.
///
/// Both platforms only support this for *installed* (non-debug-sideloaded
/// via some CI configs) apps signed the normal way — it's a no-op with a
/// caught, logged error on anything unexpected rather than crashing the app,
/// since a failed icon swap should never block using the app.
class AppIconSwitcher {
  AppIconSwitcher._();

  static const _channel = MethodChannel('project_wellness/app_icon');

  static Future<void> setIcon(AppThemeSeed seed) async {
    final iconKey = switch (seed) {
      AppThemeSeed.classic => 'green',
      AppThemeSeed.pink => 'pink',
    };
    try {
      await _channel.invokeMethod<void>('setIcon', {'seed': iconKey});
    } on PlatformException catch (e) {
      debugPrint('AppIconSwitcher: failed to switch icon: $e');
    } on MissingPluginException {
      // No platform-side handler registered (e.g. running on web/desktop
      // during development) — icon switching simply isn't available there.
    }
  }
}
