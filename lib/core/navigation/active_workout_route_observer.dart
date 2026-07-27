import 'package:flutter/material.dart';

/// Registered on `MaterialApp.navigatorObservers` in `app.dart` and
/// subscribed to by `ActiveWorkoutScreen` (a `RouteAware`) so it can tell
/// the app when it's the visible top route vs. covered by another screen —
/// used to hide the global persistent active-workout bar exactly while
/// the full active-workout screen is already showing, so there's never a
/// duplicate timer/bar on screen at once.
final RouteObserver<PageRoute<dynamic>> activeWorkoutRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

/// The app's single root `Navigator`, set as `MaterialApp.navigatorKey` in
/// `app.dart`. Widgets rendered via `MaterialApp.builder` (like
/// `ActiveWorkoutBar`) sit *above* the Navigator in the widget tree, not
/// inside it — `Navigator.of(context)` from one of those widgets' own
/// `context` finds no Navigator ancestor and throws. Pushing through this
/// key instead works regardless of where the calling widget lives.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
