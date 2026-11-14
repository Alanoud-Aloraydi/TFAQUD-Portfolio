import CoreLocation
import Flutter
import UIKit
import UserNotifications
import WeatherKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var accessibilityChannel: FlutterMethodChannel?
  private var weatherChannel: FlutterMethodChannel?
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
    // passes the notifications to the plugins, so a reminder shows while the
    // app is open, and a tap on one reaches the app. The server's pushes
    // (OneSignal) register and answer their taps in its own plugin.
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

  @objc private func transparencyPreferenceChanged() {
    accessibilityChannel?.invokeMethod(
      "reduceTransparencyChanged",
      arguments: UIAccessibility.isReduceTransparencyEnabled
    )
  }
}
