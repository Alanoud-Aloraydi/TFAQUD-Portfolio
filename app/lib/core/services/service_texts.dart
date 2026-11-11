/// Words shown by the phone itself (notification actions, the notification
/// channel, the calendar), fixed here because the translations are not
/// loaded when these services start. Keep them in friendly colloquial Arabic.
abstract final class ServiceTexts {
  /// The snooze action on a dose or measurement reminder.
  static const String snoozeAction = 'ذكّرني بعد 15 دقيقة';

  /// The Android channel of the reminders, as the phone's settings list it.
  static const String channelName = 'التذكيرات';

  /// What the Android channel tells the person it is for.
  static const String channelDescription = 'تذكير الجرعات والقياسات والمواعيد';

  /// The name of the app's own calendar on the phone. Also used to find an
  /// old calendar left by an earlier install, so renaming it orphans those.
  static const String calendarName = 'تفقّد';
}
