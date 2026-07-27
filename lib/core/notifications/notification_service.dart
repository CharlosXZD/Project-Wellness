import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules and cancels the app's local (on-device) reminders — meal
/// logging, weigh-in, workout, and backup nudges. No backend/accounts
/// involved; everything is a plain OS-scheduled notification.
///
/// Android alarms are scheduled inexact (`inexactAllowWhileIdle`) rather than
/// exact, so the app doesn't need `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` or
/// the Play Store's special-permission declaration for it — a reminder may
/// fire within roughly a 15-minute window rather than to-the-minute, which is
/// fine for "log your dinner" style nudges.
///
/// Scheduled alarms are cleared by the OS on device reboot (no
/// boot-completed receiver is set up); `SettingsRepository.load()` re-arms
/// everything from persisted settings on every app launch, so this only
/// matters if the phone reboots and the app isn't reopened before the next
/// reminder time.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _breakfastId = 1;
  static const _lunchId = 2;
  static const _dinnerId = 3;
  static const _weighInId = 4;
  static const _workoutId = 5;
  static const _backupId = 6;

  static const _channelId = 'reminders';
  static const _channelName = 'Reminders';
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Meal, weigh-in, and workout reminders',
    ),
    iOS: DarwinNotificationDetails(),
  );

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Cached so `onWorkoutLogged` (called from TrainingRepository, which has no
  // reference to SettingsRepository) knows whether/when to suppress today's
  // workout reminder, without the two repositories depending on each other.
  bool _workoutReminderEnabled = false;
  TimeOfDay _workoutReminderTime = const TimeOfDay(hour: 18, minute: 0);

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (e) {
      // Falls back to whatever `package:timezone` defaults to (UTC) —
      // reminders would fire at the wrong wall-clock time, but this
      // shouldn't happen on real devices and must never block app startup.
      debugPrint('NotificationService: failed to resolve local timezone: $e');
    }

    const androidSettings = AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  /// Requests OS notification permission. Call lazily, the first time the
  /// user enables a reminder toggle — not upfront at app launch.
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      // Returns null on API <33, where there's no runtime prompt to grant.
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<void> scheduleBreakfastReminder(TimeOfDay time) => _scheduleDaily(
        _breakfastId,
        title: 'Log your breakfast',
        body: "Don't forget to track what you had this morning.",
        time: time,
      );

  Future<void> cancelBreakfastReminder() => _cancel(_breakfastId);

  Future<void> scheduleLunchReminder(TimeOfDay time) => _scheduleDaily(
        _lunchId,
        title: 'Log your lunch',
        body: "Don't forget to track today's lunch.",
        time: time,
      );

  Future<void> cancelLunchReminder() => _cancel(_lunchId);

  Future<void> scheduleDinnerReminder(TimeOfDay time) => _scheduleDaily(
        _dinnerId,
        title: 'Log your dinner',
        body: "Don't forget to track tonight's dinner.",
        time: time,
      );

  Future<void> cancelDinnerReminder() => _cancel(_dinnerId);

  Future<void> scheduleWeighInReminder(TimeOfDay time) => _scheduleDaily(
        _weighInId,
        title: 'Time to weigh in',
        body: "Log today's weight to keep your progress chart up to date.",
        time: time,
      );

  Future<void> cancelWeighInReminder() => _cancel(_weighInId);

  Future<void> scheduleWorkoutReminder(TimeOfDay time) async {
    _workoutReminderEnabled = true;
    _workoutReminderTime = time;
    await _scheduleDaily(
      _workoutId,
      title: 'Workout reminder',
      body: "You haven't logged a workout today — get moving!",
      time: time,
    );
  }

  Future<void> cancelWorkoutReminder() async {
    _workoutReminderEnabled = false;
    await _cancel(_workoutId);
  }

  /// Weekly (Sundays), not daily — a backup nudge doesn't need to be daily,
  /// and this avoids adding a day-of-week picker to the Reminders screen for
  /// a single reminder type.
  Future<void> scheduleBackupReminder(TimeOfDay time) async {
    await init();
    await _plugin.zonedSchedule(
      id: _backupId,
      title: 'Back up your data',
      body: 'A quick reminder to export a backup file in Settings.',
      scheduledDate: _nextSundayInstanceOf(time),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelBackupReminder() => _cancel(_backupId);

  // Cached per app-session so an unlock streak doesn't re-prompt for
  // permission on every single medal — ask once, remember the answer,
  // silently skip firing if it was declined.
  bool? _unlockPermissionGranted;

  /// Fires an immediate "medal unlocked" push — unlike the reminders above,
  /// this is a one-off `show()`, not a scheduled `zonedSchedule()`. Lazily
  /// requests notification permission the first time this is called in a
  /// session, same "ask lazily, not upfront" convention as [requestPermission]
  /// elsewhere in this class; if the user declines, this silently no-ops for
  /// the rest of the session rather than nagging on every subsequent unlock.
  Future<void> notifyMedalUnlocked(String title) async {
    await init();
    _unlockPermissionGranted ??= await requestPermission();
    if (_unlockPermissionGranted != true) return;

    await _plugin.show(
      id: 1000 + title.hashCode.abs() % 1000,
      title: 'Medal unlocked!',
      body: title,
      notificationDetails: _details,
    );
  }

  /// Called by `TrainingRepository.addSession` whenever a session is logged.
  /// If it's for today and the workout reminder is currently enabled,
  /// postpones the next occurrence to tomorrow so the user isn't nagged
  /// about a workout they already did.
  Future<void> onWorkoutLogged(DateTime sessionDate) async {
    if (!_workoutReminderEnabled) return;
    final now = DateTime.now();
    final isToday = sessionDate.year == now.year &&
        sessionDate.month == now.month &&
        sessionDate.day == now.day;
    if (!isToday) return;

    await init();
    await _cancel(_workoutId);
    final tomorrow = tz.TZDateTime.now(tz.local).add(const Duration(days: 1));
    final scheduled = tz.TZDateTime(
      tz.local,
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      _workoutReminderTime.hour,
      _workoutReminderTime.minute,
    );
    await _plugin.zonedSchedule(
      id: _workoutId,
      title: 'Workout reminder',
      body: "You haven't logged a workout today — get moving!",
      scheduledDate: scheduled,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleDaily(
    int id, {
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOf(time),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextSundayInstanceOf(TimeOfDay time) {
    var scheduled = _nextInstanceOf(time);
    while (scheduled.weekday != DateTime.sunday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
