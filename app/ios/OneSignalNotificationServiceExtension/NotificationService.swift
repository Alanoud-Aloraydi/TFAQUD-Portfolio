import OneSignalExtension
import UserNotifications

/// Runs for each of the server's pushes that come through OneSignal before
/// iOS shows it: OneSignal reports the delivery and keeps the app's badge
/// right (through the App Group it shares with the app). The phone's own
/// reminders do not pass here.
class NotificationService: UNNotificationServiceExtension {

  var contentHandler: ((UNNotificationContent) -> Void)?
  var receivedRequest: UNNotificationRequest!
  var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.receivedRequest = request
    self.contentHandler = contentHandler
    self.bestAttemptContent =
      (request.content.mutableCopy() as? UNMutableNotificationContent)

    if let bestAttemptContent = bestAttemptContent {
      OneSignalExtension.didReceiveNotificationExtensionRequest(
        self.receivedRequest,
        with: bestAttemptContent,
        withContentHandler: self.contentHandler
      )
    }
  }

  override func serviceExtensionTimeWillExpire() {
    // Out of time: iOS shows the push as it came.
    if let contentHandler = contentHandler,
      let bestAttemptContent = bestAttemptContent
    {
      OneSignalExtension.serviceExtensionTimeWillExpireRequest(
        self.receivedRequest,
        with: self.bestAttemptContent
      )
      contentHandler(bestAttemptContent)
    }
  }
}
