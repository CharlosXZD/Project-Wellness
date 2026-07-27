import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @selectSexError.
  ///
  /// In en, this message translates to:
  /// **'Select male or female'**
  String get selectSexError;

  /// No description provided for @selectDobError.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get selectDobError;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nProject Wellness'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your profile. This stays on your device — no accounts, no cloud.'**
  String get onboardingSubtitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @nameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get nameRequiredError;

  /// No description provided for @dobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dobLabel;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @weightLabelWithUnit.
  ///
  /// In en, this message translates to:
  /// **'Weight ({unit})'**
  String weightLabelWithUnit(String unit);

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// No description provided for @heightCmLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCmLabel;

  /// No description provided for @heightFtLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (ft)'**
  String get heightFtLabel;

  /// No description provided for @inLabel.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get inLabel;

  /// No description provided for @activityLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'How active are you day to day?'**
  String get activityLevelLabel;

  /// No description provided for @activityLevelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — helps estimate your calories more accurately from the start, before we have any workout history to go on.'**
  String get activityLevelSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String greeting(String name);

  /// No description provided for @trackPrompt.
  ///
  /// In en, this message translates to:
  /// **'What would you like to track?'**
  String get trackPrompt;

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @trainingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Workouts & weight'**
  String get trainingSubtitle;

  /// No description provided for @nutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutrition;

  /// No description provided for @nutritionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calories & macros'**
  String get nutritionSubtitle;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day streak} other{{count} day streak}}'**
  String streakDays(int count);

  /// No description provided for @replaceAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all data?'**
  String get replaceAllDataTitle;

  /// No description provided for @replaceAllDataContent.
  ///
  /// In en, this message translates to:
  /// **'This replaces ALL current data — profile, workouts, nutrition, and weight history — with the contents of this file. This can\'t be undone.'**
  String get replaceAllDataContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @dataRestored.
  ///
  /// In en, this message translates to:
  /// **'Data restored'**
  String get dataRestored;

  /// No description provided for @deleteAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllDataTitle;

  /// No description provided for @deleteAllDataContent.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your profile, workouts, nutrition log, and weight history from this device. There\'s no undo unless you exported a backup first. You\'ll be taken back to setup.'**
  String get deleteAllDataContent;

  /// No description provided for @deleteEverything.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get deleteEverything;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your birthday, height, and weight'**
  String get editProfileSubtitle;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @remindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Meal, weigh-in, and workout notifications'**
  String get remindersSubtitle;

  /// No description provided for @cycleTracking.
  ///
  /// In en, this message translates to:
  /// **'Cycle tracking'**
  String get cycleTracking;

  /// No description provided for @cycleTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — track your cycle for phase insights'**
  String get cycleTrackingSubtitle;

  /// No description provided for @personalExercises.
  ///
  /// In en, this message translates to:
  /// **'Personal Exercises'**
  String get personalExercises;

  /// No description provided for @personalExercisesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exercises you\'ve created yourself'**
  String get personalExercisesSubtitle;

  /// No description provided for @personalFoods.
  ///
  /// In en, this message translates to:
  /// **'Personal Foods'**
  String get personalFoods;

  /// No description provided for @personalFoodsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Foods you\'ve created yourself'**
  String get personalFoodsSubtitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Follow your system setting, or pin light/dark. Pick a color theme for the whole app.'**
  String get appearanceDescription;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @unitsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how weight and height are shown throughout the app.'**
  String get unitsDescription;

  /// No description provided for @appleHealth.
  ///
  /// In en, this message translates to:
  /// **'Apple Health'**
  String get appleHealth;

  /// No description provided for @healthConnect.
  ///
  /// In en, this message translates to:
  /// **'Health Connect'**
  String get healthConnect;

  /// No description provided for @healthSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Send weight and workouts you log here to {service}, and use your step count to improve the calorie target estimate.'**
  String healthSyncDescription(String service);

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @faceIdTouchId.
  ///
  /// In en, this message translates to:
  /// **'Face ID/Touch ID'**
  String get faceIdTouchId;

  /// No description provided for @fingerprintOrFace.
  ///
  /// In en, this message translates to:
  /// **'your fingerprint or face'**
  String get fingerprintOrFace;

  /// No description provided for @privacyDescription.
  ///
  /// In en, this message translates to:
  /// **'Require {method} to open the app.'**
  String privacyDescription(String method);

  /// No description provided for @yourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourData;

  /// No description provided for @yourDataDescription.
  ///
  /// In en, this message translates to:
  /// **'No cloud, nothing leaves your phone unless you send it yourself. Back up everything to a file, or restore it on a new device.'**
  String get yourDataDescription;

  /// No description provided for @exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get exportMyData;

  /// No description provided for @exportMyDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a backup file directly to your phone\'s storage'**
  String get exportMyDataSubtitle;

  /// No description provided for @shareBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Share backup file'**
  String get shareBackupFile;

  /// No description provided for @shareBackupFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send it via AirDrop, email, or another app'**
  String get shareBackupFileSubtitle;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importData;

  /// No description provided for @importDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup file'**
  String get importDataSubtitle;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @dangerZoneDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently erase everything stored on this device.'**
  String get dangerZoneDescription;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile, workouts, nutrition, weight history'**
  String get deleteAllDataCardSubtitle;

  /// No description provided for @themeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get themeClassic;

  /// No description provided for @themePink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get themePink;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @unitSystemMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get unitSystemMetric;

  /// No description provided for @unitSystemImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get unitSystemImperial;

  /// No description provided for @healthPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'{service} permission was not granted.'**
  String healthPermissionDenied(String service);

  /// No description provided for @syncWithService.
  ///
  /// In en, this message translates to:
  /// **'Sync with {service}'**
  String syncWithService(String service);

  /// No description provided for @noBiometricsSetUp.
  ///
  /// In en, this message translates to:
  /// **'This device has no fingerprint, face, or passcode set up.'**
  String get noBiometricsSetUp;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed.'**
  String get authenticationFailed;

  /// No description provided for @fingerprintSlashFace.
  ///
  /// In en, this message translates to:
  /// **'fingerprint/face'**
  String get fingerprintSlashFace;

  /// No description provided for @requireBiometric.
  ///
  /// In en, this message translates to:
  /// **'Require {method}'**
  String requireBiometric(String method);

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for Project Wellness — enable them in your device Settings to use reminders.'**
  String get notificationsOff;

  /// No description provided for @localOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Local notifications only — nothing leaves your phone.'**
  String get localOnlyNotice;

  /// No description provided for @breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// No description provided for @breakfastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me to log breakfast'**
  String get breakfastSubtitle;

  /// No description provided for @lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// No description provided for @lunchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me to log lunch'**
  String get lunchSubtitle;

  /// No description provided for @dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// No description provided for @dinnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me to log dinner'**
  String get dinnerSubtitle;

  /// No description provided for @weighIn.
  ///
  /// In en, this message translates to:
  /// **'Weigh-in'**
  String get weighIn;

  /// No description provided for @weighInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me to log my weight'**
  String get weighInSubtitle;

  /// No description provided for @workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @workoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Skipped automatically once you\'ve logged a workout that day'**
  String get workoutSubtitle;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @backupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly reminder to export a backup file (Sundays)'**
  String get backupSubtitle;

  /// No description provided for @appLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Project Wellness is locked'**
  String get appLockedTitle;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @unlocking.
  ///
  /// In en, this message translates to:
  /// **'Unlocking…'**
  String get unlocking;

  /// No description provided for @cycleTrackingNotice.
  ///
  /// In en, this message translates to:
  /// **'Available to anyone who wants it — not tied to your profile. Everything stays on this device.'**
  String get cycleTrackingNotice;

  /// No description provided for @cycleTrackingEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable cycle tracking'**
  String get cycleTrackingEnable;

  /// No description provided for @cycleTrackingEnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log period start dates to see your current phase'**
  String get cycleTrackingEnableSubtitle;

  /// No description provided for @cycleAdjustCaloriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust calorie target for luteal phase'**
  String get cycleAdjustCaloriesTitle;

  /// No description provided for @cycleAdjustCaloriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adds a small, fixed estimate during the luteal phase — not a precise measurement'**
  String get cycleAdjustCaloriesSubtitle;

  /// No description provided for @cyclePeriodHistory.
  ///
  /// In en, this message translates to:
  /// **'Period history'**
  String get cyclePeriodHistory;

  /// No description provided for @cycleLogPeriodStart.
  ///
  /// In en, this message translates to:
  /// **'Log period start'**
  String get cycleLogPeriodStart;

  /// No description provided for @cycleNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No period start dates logged yet'**
  String get cycleNoEntries;

  /// No description provided for @cycleCurrentPhase.
  ///
  /// In en, this message translates to:
  /// **'Current phase'**
  String get cycleCurrentPhase;

  /// No description provided for @cycleNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet'**
  String get cycleNotEnoughData;

  /// No description provided for @cyclePhaseMenstrual.
  ///
  /// In en, this message translates to:
  /// **'Menstrual'**
  String get cyclePhaseMenstrual;

  /// No description provided for @cyclePhaseFollicular.
  ///
  /// In en, this message translates to:
  /// **'Follicular'**
  String get cyclePhaseFollicular;

  /// No description provided for @cyclePhaseOvulation.
  ///
  /// In en, this message translates to:
  /// **'Ovulation'**
  String get cyclePhaseOvulation;

  /// No description provided for @cyclePhaseLuteal.
  ///
  /// In en, this message translates to:
  /// **'Luteal'**
  String get cyclePhaseLuteal;

  /// No description provided for @cycleDeleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get cycleDeleteEntry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
