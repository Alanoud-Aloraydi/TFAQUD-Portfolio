import CoreLocation
import Flutter
import UIKit
import UserNotifications
import WeatherKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var accessibilityChannel: FlutterMethodChannel?
  private var pushChannel: FlutterMethodChannel?
  private var pushTapChannel: FlutterMethodChannel?
  private var weatherChannel: FlutterMethodChannel?
  /// The kind of a push tapped before Dart listened (the push that launched
  /// the app); Dart takes it once with "launchTap".
  private var launchPushKind: String?
  private var dartTakesPushTaps = false
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

    // Taps on the server's pushes. flutter_local_notifications passes on
    // only its own notifications, so userNotificationCenter(didReceive:)
    // below sends a push's `kind` here, to the same Dart taps stream as the
    // reminders (PhoneNotifications.taps).
    let pushTaps = FlutterMethodChannel(
      name: "tafaqod/push_taps",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    pushTapChannel = pushTaps
    pushTaps.setMethodCallHandler { [weak self] call, result in
      if call.method == "launchTap" {
        self?.dartTakesPushTaps = true
        result(self?.launchPushKind)
        self?.launchPushKind = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // The weather now in the patient's city, for «اليوم»: Apple Weather
    // (WeatherKit) on the phone, with no key and no location permission;
    // Dart sends the city's coordinates. Before iOS 16, or when WeatherKit
    // cannot answer (no capability, no network), the answer is nil and the
    // app shows no weather.
    let weather = FlutterMethodChannel(
      name: "tafaqod/weather",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    weatherChannel = weather
    weather.setMethodCallHandler { call, result in
      guard call.method == "current",
        let place = call.arguments as? [String: Any],
        let latitude = place["latitude"] as? Double,
        let longitude = place["longitude"] as? Double
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      if #available(iOS 16.0, *) {
        Task { @MainActor in
          result(
            await AppDelegate.currentWeather(
              latitude: latitude, longitude: longitude))
        }
      } else {
        result(nil)
      }
    }
  }

  /// The weather now at a place, with Apple's attribution that must show
  /// beside it (the Apple Weather mark and the legal page); nil when
  /// WeatherKit cannot answer.
  @available(iOS 16.0, *)
  private static func currentWeather(
    latitude: Double, longitude: Double
  ) async -> [String: Any]? {
    let service = WeatherService.shared
    do {
      let current = try await service.weather(
        for: CLLocation(latitude: latitude, longitude: longitude),
        including: .current
      )
      let attribution = try await service.attribution
      return [
        "temperature": current.temperature.converted(to: .celsius).value,
        "condition": current.condition.rawValue,
        "is_daylight": current.isDaylight,
        "mark_light": attribution.combinedMarkLightURL.absoluteString,
        "mark_dark": attribution.combinedMarkDarkURL.absoluteString,
        "legal_page": attribution.legalPageURL.absoluteString,
      ]
    } catch {
      return nil
    }
  }

  /// A tap on a notification. A server push goes to Dart as its `kind`
  /// (kept for "launchTap" until Dart listens); a reminder goes to the
  /// plugins, as before.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let request = response.notification.request
    guard request.trigger is UNPushNotificationTrigger,
      let kind = request.content.userInfo["kind"] as? String
    else {
      super.userNotificationCenter(
        center, didReceive: response, withCompletionHandler: completionHandler)
      return
    }
    if dartTakesPushTaps {
      pushTapChannel?.invokeMethod("tap", arguments: kind)
    } else {
      launchPushKind = kind
    }
    completionHandler()
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
