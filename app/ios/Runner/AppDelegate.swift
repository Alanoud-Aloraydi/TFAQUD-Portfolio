import CoreLocation
import Flutter
import UIKit
import UserNotifications
import WeatherKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var accessibilityChannel: FlutterMethodChannel?
  private var weatherChannel: FlutterMethodChannel?
  // The app's own reminders that were tapped (see `keepReminderTap`): kept
  // here until Dart asks for them, then sent as they come.
  private var reminderTapsChannel: FlutterMethodChannel?
  private var dartTakesReminderTaps = false
  private var waitingReminderTaps: [[String: String]] = []
  private var seenReminderTaps = Set<String>()
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The app is Arabic only. Flutter lays itself out right to left, but the
    // native views (the iOS 26 glass tab bar) follow UIKit, which would be
    // left to right without an Arabic .lproj. This puts the first tab on the
    // right and the add button on the left, as iOS does in Arabic.
    UIView.appearance().semanticContentAttribute = .forceRightToLeft
    // Set before launch ends, as Apple asks: the tap that opens the closed
    // app comes right after. The app's reminders (flutter_local_notifications)
    // are shown by the plugins, and their taps kept here
    // (`keepReminderTap`); the server's pushes (OneSignal) answer their taps
    // in its own SDK.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Dart asks once for the reminder taps that came before it was ready;
    // the ones after come to it as they happen.
    let reminderTaps = FlutterMethodChannel(
      name: "tafaqod/reminder_taps",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    reminderTapsChannel = reminderTaps
    reminderTaps.setMethodCallHandler { [weak self] call, result in
      guard call.method == "listen", let self = self else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.dartTakesReminderTaps = true
      result(self.waitingReminderTaps)
      self.waitingReminderTaps.removeAll()
    }
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

  /// A tap on a notification. The app's reminders are answered here, in
  /// every state of the app: under scenes, Flutter registers its plugins
  /// only after launch, so the tap that opens the closed app would reach no
  /// plugin and be lost. Anything else goes on to the plugins.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if keepReminderTap(response) {
      completionHandler()
      return
    }
    super.userNotificationCenter(
      center, didReceive: response, withCompletionHandler: completionHandler)
  }

  /// Keeps a tap on one of the app's reminders for Dart: its payload, and
  /// the action pressed ("" for the reminder itself). False for any other
  /// notification. The scene's launch options and this delegate can both
  /// bring the tap that opened the app; it is kept once.
  @discardableResult
  func keepReminderTap(_ response: UNNotificationResponse) -> Bool {
    let info = response.notification.request.content.userInfo
    guard let payload = info["payload"] as? String, info["presentAlert"] != nil
    else { return false }
    if response.actionIdentifier == UNNotificationDismissActionIdentifier {
      return true
    }
    let action =
      response.actionIdentifier == UNNotificationDefaultActionIdentifier
      ? "" : response.actionIdentifier
    let key = [
      response.notification.request.identifier,
      String(response.notification.date.timeIntervalSince1970),
      action,
    ].joined(separator: "|")
    let tap = ["payload": payload, "action": action]
    DispatchQueue.main.async {
      guard self.seenReminderTaps.insert(key).inserted else { return }
      if self.dartTakesReminderTaps, let channel = self.reminderTapsChannel {
        channel.invokeMethod("tap", arguments: tap)
      } else {
        self.waitingReminderTaps.append(tap)
      }
    }
    return true
  }

  @objc private func transparencyPreferenceChanged() {
    accessibilityChannel?.invokeMethod(
      "reduceTransparencyChanged",
      arguments: UIAccessibility.isReduceTransparencyEnabled
    )
  }
}
