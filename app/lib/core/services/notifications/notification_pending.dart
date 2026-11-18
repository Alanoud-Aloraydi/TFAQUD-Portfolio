import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The notifications [plugin] has scheduled that have not shown yet: id to
/// payload.
Future<Map<int, String>> pendingNotificationPayloads(
  FlutterLocalNotificationsPlugin plugin,
) async {
  final List<PendingNotificationRequest> requests = await plugin
      .pendingNotificationRequests();
  return <int, String>{
    for (final PendingNotificationRequest request in requests)
      request.id: request.payload ?? '',
  };
}
