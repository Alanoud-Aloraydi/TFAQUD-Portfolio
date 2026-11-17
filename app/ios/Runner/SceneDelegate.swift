import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  // A reminder tapped while the app was closed also comes with the scene's
  // connection options; AppDelegate keeps it for Dart, once.
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    if let response = connectionOptions.notificationResponse {
      (UIApplication.shared.delegate as? AppDelegate)?.keepReminderTap(response)
    }
  }
}
