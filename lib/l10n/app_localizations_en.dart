// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get selectSexError => 'Select male or female';

  @override
  String get selectDobError => 'Select your date of birth';

  @override
  String get onboardingTitle => 'Welcome to\nProject Wellness';

  @override
  String get onboardingSubtitle =>
      'Let\'s set up your profile. This stays on your device — no accounts, no cloud.';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameRequiredError => 'Enter your name';

  @override
  String get dobLabel => 'Date of birth';

  @override
  String get selectDate => 'Select date';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String weightLabelWithUnit(String unit) {
    return 'Weight ($unit)';
  }

  @override
  String get invalid => 'Invalid';

  @override
  String get heightCmLabel => 'Height (cm)';

  @override
  String get heightFtLabel => 'Height (ft)';

  @override
  String get inLabel => 'in';

  @override
  String get activityLevelLabel => 'How active are you day to day?';

  @override
  String get activityLevelSubtitle =>
      'Optional — helps estimate your calories more accurately from the start, before we have any workout history to go on.';

  @override
  String get getStarted => 'Get started';

  @override
  String get settingsTitle => 'Settings';

  @override
  String greeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get trackPrompt => 'What would you like to track?';

  @override
  String get training => 'Training';

  @override
  String get trainingSubtitle => 'Workouts & weight';

  @override
  String get nutrition => 'Nutrition';

  @override
  String get nutritionSubtitle => 'Calories & macros';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String get replaceAllDataTitle => 'Replace all data?';

  @override
  String get replaceAllDataContent =>
      'This replaces ALL current data — profile, workouts, nutrition, and weight history — with the contents of this file. This can\'t be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get replace => 'Replace';

  @override
  String get dataRestored => 'Data restored';

  @override
  String get deleteAllDataTitle => 'Delete all data?';

  @override
  String get deleteAllDataContent =>
      'This permanently deletes your profile, workouts, nutrition log, and weight history from this device. There\'s no undo unless you exported a backup first. You\'ll be taken back to setup.';

  @override
  String get deleteEverything => 'Delete everything';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get editProfileSubtitle => 'Update your birthday, height, and weight';

  @override
  String get reminders => 'Reminders';

  @override
  String get remindersSubtitle => 'Meal, weigh-in, and workout notifications';

  @override
  String get cycleTracking => 'Cycle tracking';

  @override
  String get cycleTrackingSubtitle =>
      'Optional — track your cycle for phase insights';

  @override
  String get personalExercises => 'Personal Exercises';

  @override
  String get personalExercisesSubtitle => 'Exercises you\'ve created yourself';

  @override
  String get personalFoods => 'Personal Foods';

  @override
  String get personalFoodsSubtitle => 'Foods you\'ve created yourself';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceDescription =>
      'Follow your system setting, or pin light/dark. Pick a color theme for the whole app.';

  @override
  String get units => 'Units';

  @override
  String get unitsDescription =>
      'Choose how weight and height are shown throughout the app.';

  @override
  String get appleHealth => 'Apple Health';

  @override
  String get healthConnect => 'Health Connect';

  @override
  String healthSyncDescription(String service) {
    return 'Send weight and workouts you log here to $service, and use your step count to improve the calorie target estimate.';
  }

  @override
  String get privacy => 'Privacy';

  @override
  String get faceIdTouchId => 'Face ID/Touch ID';

  @override
  String get fingerprintOrFace => 'your fingerprint or face';

  @override
  String privacyDescription(String method) {
    return 'Require $method to open the app.';
  }

  @override
  String get yourData => 'Your data';

  @override
  String get yourDataDescription =>
      'No cloud, nothing leaves your phone unless you send it yourself. Back up everything to a file, or restore it on a new device.';

  @override
  String get exportMyData => 'Save to device';

  @override
  String get exportMyDataSubtitle =>
      'Save a backup file directly to your phone\'s storage';

  @override
  String get shareBackupFile => 'Share backup file';

  @override
  String get shareBackupFileSubtitle =>
      'Send it via AirDrop, email, or another app';

  @override
  String get importData => 'Import data';

  @override
  String get importDataSubtitle => 'Restore from a backup file';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get dangerZoneDescription =>
      'Permanently erase everything stored on this device.';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get deleteAllDataCardSubtitle =>
      'Profile, workouts, nutrition, weight history';

  @override
  String get themeClassic => 'Classic';

  @override
  String get themePink => 'Pink';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get unitSystemMetric => 'Metric';

  @override
  String get unitSystemImperial => 'Imperial';

  @override
  String healthPermissionDenied(String service) {
    return '$service permission was not granted.';
  }

  @override
  String syncWithService(String service) {
    return 'Sync with $service';
  }

  @override
  String get noBiometricsSetUp =>
      'This device has no fingerprint, face, or passcode set up.';

  @override
  String get authenticationFailed => 'Authentication failed.';

  @override
  String get fingerprintSlashFace => 'fingerprint/face';

  @override
  String requireBiometric(String method) {
    return 'Require $method';
  }

  @override
  String get notificationsOff =>
      'Notifications are turned off for Project Wellness — enable them in your device Settings to use reminders.';

  @override
  String get localOnlyNotice =>
      'Local notifications only — nothing leaves your phone.';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get breakfastSubtitle => 'Remind me to log breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get lunchSubtitle => 'Remind me to log lunch';

  @override
  String get dinner => 'Dinner';

  @override
  String get dinnerSubtitle => 'Remind me to log dinner';

  @override
  String get weighIn => 'Weigh-in';

  @override
  String get weighInSubtitle => 'Remind me to log my weight';

  @override
  String get workout => 'Workout';

  @override
  String get workoutSubtitle =>
      'Skipped automatically once you\'ve logged a workout that day';

  @override
  String get backup => 'Backup';

  @override
  String get backupSubtitle =>
      'Weekly reminder to export a backup file (Sundays)';

  @override
  String get appLockedTitle => 'Project Wellness is locked';

  @override
  String get unlock => 'Unlock';

  @override
  String get unlocking => 'Unlocking…';

  @override
  String get cycleTrackingNotice =>
      'Available to anyone who wants it — not tied to your profile. Everything stays on this device.';

  @override
  String get cycleTrackingEnable => 'Enable cycle tracking';

  @override
  String get cycleTrackingEnableSubtitle =>
      'Log period start dates to see your current phase';

  @override
  String get cycleAdjustCaloriesTitle =>
      'Adjust calorie target for luteal phase';

  @override
  String get cycleAdjustCaloriesSubtitle =>
      'Adds a small, fixed estimate during the luteal phase — not a precise measurement';

  @override
  String get cyclePeriodHistory => 'Period history';

  @override
  String get cycleLogPeriodStart => 'Log period start';

  @override
  String get cycleNoEntries => 'No period start dates logged yet';

  @override
  String get cycleCurrentPhase => 'Current phase';

  @override
  String get cycleNotEnoughData => 'Not enough data yet';

  @override
  String get cyclePhaseMenstrual => 'Menstrual';

  @override
  String get cyclePhaseFollicular => 'Follicular';

  @override
  String get cyclePhaseOvulation => 'Ovulation';

  @override
  String get cyclePhaseLuteal => 'Luteal';

  @override
  String get cycleDeleteEntry => 'Delete entry';

  @override
  String cycleNextPeriodIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Next period in $count days',
      one: 'Next period in 1 day',
      zero: 'Period expected today',
    );
    return '$_temp0';
  }

  @override
  String cyclePeriodLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Period is $count days late',
      one: 'Period is 1 day late',
    );
    return '$_temp0';
  }

  @override
  String cycleExpectedOn(String date) {
    return 'Expected $date';
  }

  @override
  String get cycleOvulationEstimate => 'Estimated ovulation';

  @override
  String get cycleFertileWindow => 'Fertile window';

  @override
  String get cycleLengthLabel => 'Cycle length';

  @override
  String cycleLengthValue(int count) {
    return '$count days';
  }

  @override
  String cycleLengthLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Learned from your last $count cycles',
      one: 'Learned from 1 cycle',
      zero: 'Default until you log two periods',
    );
    return '$_temp0';
  }

  @override
  String get cycleEstimateDisclaimer =>
      'Estimates only, based on your logged dates. Not suitable for contraception.';

  @override
  String get cycleDuplicateTitle => 'Same period?';

  @override
  String cycleDuplicateContent(String date) {
    return '$date is within a few days of a period start you already logged. Cycle estimates treat those as one period.';
  }

  @override
  String get cycleLogAnyway => 'Log anyway';

  @override
  String get cycleEntryDeleted => 'Period start removed';

  @override
  String get undo => 'Undo';

  @override
  String get cycleStaleData =>
      'Log your most recent period start to see where you are';
}
