import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var accessibilityChannel: FlutterMethodChannel?
  private var pushChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The app is Arabic only. Flutter lays itself out right to left, but the
    // native views (the iOS 26 glass tab bar) follow UIKit, which would be
    // left to right without an Arabic .lproj. This puts the first tab on the
    // right and the add button on the left, as iOS does in Arabic.
    UIView.appearance().semanticContentAttribute = .forceRightToLeft
    // The dose reminders (flutter_local_notifications): the app delegate
    // passes the notifications to the plugin, so a reminder shows while the
    // app is open, and a tap on one reaches the app.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "tafaqod/accessibility",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    accessibilityChannel = channel
    channel.setMethodCallHandler { call, result in
      if call.method == "reduceTransparency" {
        result(UIAccessibility.isReduceTransparencyEnabled)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(transparencyPreferenceChanged),
      name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
      object: nil
    )

    // Circle updates from the server (Apple push). Dart asks for the
    // phone's token with "register"; iOS answers in the two methods below.
    // Without the Push Notifications capability (the free Apple account)
    // iOS answers with an error, and nothing else happens.
    let push = FlutterMethodChannel(
      name: "tafaqod/push",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    pushChannel = push
    push.setMethodCallHandler { call, result in
      if call.method == "register" {
        UIApplication.shared.registerForRemoteNotifications()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    pushChannel?.invokeMethod("token", arguments: token)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
    pushChannel?.invokeMethod("tokenError", arguments: error.localizedDescription)
  }

  @objc private func transparencyPreferenceChanged() {
    accessibilityChannel?.invokeMethod(
      "reduceTransparencyChanged",
      arguments: UIAccessibility.isReduceTransparencyEnabled
    )
  }
}
