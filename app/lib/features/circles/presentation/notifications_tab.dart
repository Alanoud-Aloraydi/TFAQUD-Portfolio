import 'package:app/core/services/reminders/item_keys.dart';
import 'package:app/core/services/tap_focus.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';

/// The two lists of the bell: what waits for an answer, and what was
/// answered in the last 30 days.
enum NotificationsTab {
  current,
  previous;

  /// The tab the bell opens on: «السابقة» when the notification just
  /// tapped is about an answer that is there ([TapFocus]), else «الحالية».
  static NotificationsTab startFor(CircleInbox inbox) {
    final String? key = TapFocus.instance.waiting;
    if (!isAnsweredItem(key)) return current;
    return inbox.previous.any((item) => answeredItemKey(item.id) == key)
        ? previous
        : current;
  }
}
