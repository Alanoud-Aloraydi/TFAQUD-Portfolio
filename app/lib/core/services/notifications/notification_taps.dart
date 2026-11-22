/// The iOS action of a reminder that can be put off.
const String snoozeAction = 'snooze';

/// How long «ذكّرني لاحقًا» puts a reminder off from the notification.
const Duration notificationSnooze = Duration(minutes: 15);

/// What `PhoneNotifications.taps` gives for the snooze action: this, then
/// the reminder's own payload.
const String snoozeTapPrefix = 'snooze-action:';

/// Whether [tap] is the snooze action of a reminder, not a plain tap.
bool isSnoozeTap(String tap) => tap.startsWith(snoozeTapPrefix);

/// What `PhoneNotifications.taps` gives for a tapped server push: this,
/// its `kind`, then [pushItemSeparator] and the item (push_target.dart).
const String pushTapPrefix = 'push:';
const String pushItemSeparator = '#';

/// What `RemotePush.taps` gives for a reminder from the server: this, then
/// the tap one of the phone's own reminders would give (its payload, after
/// [snoozeTapPrefix] for «ذكّرني لاحقًا»), so both open the same task and
/// put off the same task.
const String serverReminderTapPrefix = 'server-reminder:';

/// What a tapped server push gives `PhoneNotifications.taps`: a reminder's
/// own tap, else [pushTapPrefix] and the push's text (push_target.dart).
String pushTap(String text) => text.startsWith(serverReminderTapPrefix)
    ? text.substring(serverReminderTapPrefix.length)
    : '$pushTapPrefix$text';

/// The server's `kind` of a tapped push, or null for a reminder's tap.
String? pushKind(String tap) => tap.startsWith(pushTapPrefix)
    ? tap.substring(pushTapPrefix.length).split(pushItemSeparator).first
    : null;
