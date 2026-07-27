import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../repositories/settings_repository.dart';

/// The PW brand mark (the actual approved artwork, `assets/images/pw_mark.png`
/// — a white cutout of the shape with the transparent background stripped
/// out), tinted with a dark-to-light fade of the active theme's color.
class PwLogo extends StatelessWidget {
  const PwLogo({
    super.key,
    this.seed = AppThemeSeed.classic,
    this.size = const Size(228, 102),
    this.dark,
    this.light,
  });

  final AppThemeSeed seed;
  final Size size;
  final Color? dark;
  final Color? light;

  static const _classicDark = Color(0xFF1F3A32);
  static const _classicLight = Color(0xFF8FCBB5);
  static const _pinkDark = Color(0xFF7A1D4C);
  static const _pinkLight = Color(0xFFF5A9CE);

  /// Dark stop of the fade for [seed].
  static Color darkFor(AppThemeSeed seed) => switch (seed) {
        AppThemeSeed.classic => _classicDark,
        AppThemeSeed.pink => _pinkDark,
      };

  /// Light stop of the fade for [seed].
  static Color lightFor(AppThemeSeed seed) => switch (seed) {
        AppThemeSeed.classic => _classicLight,
        AppThemeSeed.pink => _pinkLight,
      };

  @override
  Widget build(BuildContext context) {
    final resolvedDark = dark ?? darkFor(seed);
    final resolvedLight = light ?? lightFor(seed);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: [resolvedDark, resolvedLight],
        ).createShader(bounds),
        child: Image.asset(
          'assets/images/pw_mark.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// [PwLogo] wired to the user's current [SettingsRepository.themeSeed], so it
/// repaints in the matching palette wherever it's placed (splash, settings,
/// about screen) without callers needing to look up the theme themselves.
class ThemedPwLogo extends StatelessWidget {
  const ThemedPwLogo({super.key, this.size = const Size(228, 102)});

  final Size size;

  @override
  Widget build(BuildContext context) {
    final seed = context.watch<SettingsRepository>().themeSeed;
    return PwLogo(seed: seed, size: size);
  }
}
