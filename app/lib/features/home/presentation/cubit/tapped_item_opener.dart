import 'dart:async';

import 'package:app/app/services/notifications/notification_sound.dart';
import 'package:app/app/services/push_target.dart';
import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/app/services/reminders/item_keys.dart';
import 'package:app/app/services/reminders/tapped_item.dart';
import 'package:app/app/services/tap_focus.dart';
import 'package:flutter/foundation.dart' show VoidCallback;

/// Does what a tapped notification asks: «ذكّرني لاحقًا» sets the reminder
/// again and tells the person with [onSnoozed] (unless [isDisposed] by
/// then); anything else shows the item it is about.
void openTap(
  String payload, {
  required DoseReminders reminders,
  required VoidCallback openInbox,
  required void Function(String? circleId) openToday,
  required VoidCallback onSnoozed,
  required bool Function() isDisposed,
}) {
  if (isSnoozeTap(payload)) {
    unawaited(
      reminders.snoozeTap(payload).then((bool done) {
        if (done && !isDisposed()) onSnoozed();
      }),
    );
    return;
  }
  openTappedItem(payload, openInbox: openInbox, openToday: openToday);
}

/// Shows the item a tapped notification is about: the bell for an
/// invitation, a request or an answer, otherwise «اليوم» of its circle.
void openTappedItem(
  String payload, {
  required VoidCallback openInbox,
  required void Function(String? circleId) openToday,
}) {
  final String? item = tappedItemKey(payload);
  TapFocus.instance.show(item);
  if (opensBell(pushKind(payload), item)) return openInbox();
  openToday(reminderCircleId(payload) ?? itemCircleId(item));
}
