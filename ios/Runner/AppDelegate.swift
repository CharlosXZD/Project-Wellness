import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    excludeAppDataFromDeviceBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Project Wellness never sends data anywhere on its own, and that promise
  /// should hold even for the OS's own device/iCloud backup: exclude the
  /// whole Application Support directory (where the SQLite database lives —
  /// see `path_provider`'s `getApplicationSupportDirectory()`) from backup.
  /// Idempotent, safe to call on every launch.
  private func excludeAppDataFromDeviceBackup() {
    guard
      var url = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
      ).first
    else { return }
    if !FileManager.default.fileExists(atPath: url.path) {
      try? FileManager.default.createDirectory(
        at: url, withIntermediateDirectories: true)
    }
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? url.setResourceValues(values)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Required so scheduled-notification callbacks work from the background
    // action isolate flutter_local_notifications may spawn.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let iconChannel = FlutterMethodChannel(
      name: "project_wellness/app_icon",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    iconChannel.setMethodCallHandler { call, result in
      guard call.method == "setIcon" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard UIApplication.shared.supportsAlternateIcons else {
        result(nil)
        return
      }
      let args = call.arguments as? [String: Any]
      let seed = args?["seed"] as? String
      // "green" is the primary icon (nil resets to it); anything else maps
      // to the matching CFBundleAlternateIcons key in Info.plist.
      let iconName = seed == "pink" ? "AppIcon-Pink" : nil
      if UIApplication.shared.alternateIconName == iconName {
        result(nil)
        return
      }
      UIApplication.shared.setAlternateIconName(iconName) { error in
        if let error = error {
          result(
            FlutterError(
              code: "SET_ICON_FAILED", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    }
  }
}
