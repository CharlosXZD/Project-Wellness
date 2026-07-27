import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/active_workout_route_observer.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/security/app_lock_screen.dart';
import 'l10n/app_localizations.dart';
import 'repositories/active_workout_repository.dart';
import 'repositories/cycle_repository.dart';
import 'repositories/medals_repository.dart';
import 'repositories/nutrition_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/training_repository.dart';
import 'widgets/active_workout_bar.dart';

class ProjectWellnessApp extends StatelessWidget {
  const ProjectWellnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileRepository()..load()),
        ChangeNotifierProvider(create: (_) => TrainingRepository()..load()),
        ChangeNotifierProvider(create: (_) => NutritionRepository()..load()),
        ChangeNotifierProvider(create: (_) => SettingsRepository()..load()),
        ChangeNotifierProvider(create: (_) => CycleRepository()..load()),
        ChangeNotifierProvider(create: (_) => MedalsRepository()..load()),
        ChangeNotifierProvider(create: (_) => ActiveWorkoutRepository()),
      ],
      child: const _ThemedApp(),
    );
  }
}

/// Separate from [ProjectWellnessApp] so it can watch [SettingsRepository]
/// (which is provided by the [MultiProvider] above it) and rebuild
/// `MaterialApp`'s theme whenever the user picks a different one.
class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>();
    final seedColor = settings.themeSeed.seedColor;

    return MaterialApp(
      title: 'Project Wellness',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(seedColor: seedColor),
      darkTheme: AppTheme.dark(seedColor: seedColor),
      themeMode: settings.themeMode.flutterThemeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorKey: rootNavigatorKey,
      navigatorObservers: [activeWorkoutRouteObserver],
      // Overlays the persistent active-workout bar above whatever the
      // Navigator is currently showing, regardless of route — the only
      // place that works from, since every screen in this app shares one
      // root Navigator rather than nested per-tab ones. Wrapped in its own
      // Overlay because `child` here is the Navigator itself — anything
      // stacked alongside it (like the bar's tooltip) sits outside the
      // Navigator's own Overlay and would have none to attach to otherwise.
      builder: (context, child) => Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => Stack(
              children: [
                if (child != null) child,
                const Align(alignment: Alignment.bottomCenter, child: ActiveWorkoutBar()),
              ],
            ),
          ),
        ],
      ),
      home: const _AppLockGate(child: AppRoot()),
    );
  }
}

/// Gates [child] behind [AppLockScreen] when app lock is enabled — on cold
/// start, and every time the app resumes from the background. Toggling the
/// setting mid-session (from Settings) doesn't itself trigger a lock, since
/// enabling it already required a successful authentication as part of the
/// toggle flow (see `settings_screen.dart`) — only backgrounding does.
class _AppLockGate extends StatefulWidget {
  const _AppLockGate({required this.child});

  final Widget child;

  @override
  State<_AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<_AppLockGate> with WidgetsBindingObserver {
  bool _locked = false;
  bool _initializedFromSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;
    unawaited(context.read<ActiveWorkoutRepository>().flushSnapshot());
    if (context.read<SettingsRepository>().appLockEnabled) {
      setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>();

    if (!settings.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // One-time: seed the initial lock state from the persisted setting the
    // moment it becomes available (settings.load() is async, so this can't
    // happen any earlier than the first build where isLoaded is true).
    if (!_initializedFromSettings) {
      _initializedFromSettings = true;
      _locked = settings.appLockEnabled;
    }

    if (!settings.appLockEnabled || !_locked) {
      return widget.child;
    }

    return AppLockScreen(onUnlocked: () => setState(() => _locked = false));
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _restoreAttempted = false;

  @override
  Widget build(BuildContext context) {
    final profileRepo = context.watch<ProfileRepository>();
    final trainingRepo = context.watch<TrainingRepository>();

    // Fire-and-forget, once training data is available to resolve each
    // draft's exercise. Doesn't gate the first frame — the persistent
    // workout bar/screen pick the restored workout up reactively via
    // ChangeNotifier the moment it resolves.
    if (!_restoreAttempted && trainingRepo.isLoaded) {
      _restoreAttempted = true;
      unawaited(context.read<ActiveWorkoutRepository>().restoreIfAny(trainingRepo));
    }

    if (!profileRepo.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return profileRepo.hasProfile
        ? const HomeScreen()
        : const OnboardingScreen();
  }
}
