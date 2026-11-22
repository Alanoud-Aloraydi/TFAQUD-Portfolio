/// What a tapped server push is about. The server puts its `kind` and the
/// item in the push's data (backend `app/push/targets.py`); the app keeps
/// both in one line of text, `kind`, then [pushItemSeparator] and the
/// item's key (reminders/item_keys.dart). A reminder at a task's time
/// carries the payload of the phone's own reminder instead, and is tapped
/// as one ([serverReminderTapPrefix]).
library;

import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminders/item_keys.dart';

/// Whether a tapped push of [kind] opens the bell: an invitation, a
/// request, a request that can no longer be accepted, and a declined
/// answer to a request the person sent (its push names the request, which
/// is in «السابقة»). An accepted one has no card there yet and opens «اليوم».
bool opensBell(String? kind, String? item) => switch (kind) {
  'invitation' || 'circle_request' || 'request_superseded' => true,
  'request_answer' => item != null,
  _ => false,
};

/// The text of a tapped push: its `kind`, and the item when the data names
/// one; null without a kind. A reminder from the server gives the tap of
/// the phone's own reminder it carries, the snooze action's for [action]
/// [snoozeAction].
String? pushTapText(Map<String, dynamic>? data, {String? action}) {
  if (_text(data, 'reminder') case final String payload) {
    final String snooze = action == snoozeAction ? snoozeTapPrefix : '';
    return '$serverReminderTapPrefix$snooze$payload';
  }
  final String? kind = _text(data, 'kind');
  if (kind == null) return null;
  final String? item = pushItemKey(data!);
  return item == null ? kind : '$kind$pushItemSeparator$item';
}

/// The item's key of a push's [data]: a dose, a reading or a visit of
/// «اليوم», an entry of the bell, or a circle (its id alone); null when
/// the data names none.
String? pushItemKey(Map<String, dynamic> data) {
  if (_text(data, 'invitation_id') case final String id) {
    return inboxItemKey(id);
  }
  if (_text(data, 'request_id') case final String id) {
    return switch (data['kind']) {
      'request_answer' || 'request_superseded' => answeredItemKey(id),
      _ => inboxItemKey(id),
    };
  }
  final String? circle = _text(data, 'circle_id');
  if (circle == null) return null;
  final String? day = _day(_text(data, 'scheduled_on'));
  if ((_text(data, 'schedule_id'), day) case (final String id, final d?)) {
    return '$circle|$id|$d';
  }
  if ((_text(data, 'plan_version_id'), _text(data, 'time_of_day'), day) case (
    final String version,
    final String time,
    final String d,
  )) {
    return '$circle|measurement|$version|$time|$d';
  }
  if (_text(data, 'appointment_id') case final String id) {
    return appointmentItemKey(circle, id);
  }
  return circle;
}

/// The item's key of a tapped push's text ([pushTapText]), or null.
String? pushTapItem(String tap) {
  if (pushKind(tap) == null) return null;
  final int at = tap.indexOf(pushItemSeparator);
  return at < 0 ? null : tap.substring(at + 1);
}

String? _text(Map<String, dynamic>? data, String name) => switch (data?[name]) {
  final String value when value.isNotEmpty => value,
  _ => null,
};

/// A day as the snooze keys write it: «2026-11-5», without leading zeros.
String? _day(String? iso) {
  final List<int?> parts = (iso ?? '').split('-').map(int.tryParse).toList();
  if (parts.length != 3 || parts.contains(null)) return null;
  return parts.join('-');
}
