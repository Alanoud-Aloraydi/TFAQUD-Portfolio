import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The app is Arabic only. Flutter lays itself out right to left, but the
    // native views (the iOS 26 glass tab bar) follow UIKit, which would be
    // left to right without an Arabic .lproj. This puts the first tab on the
    // right and the add button on the left, as iOS does in Arabic.
    UIView.appearance().semanticContentAttribute = .forceRightToLeft
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
