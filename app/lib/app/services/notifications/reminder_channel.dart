import 'package:app/app/services/service_texts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The iOS category of a reminder that can be put off; its one action.
const String reminderCategory = 'tafaqod.reminder';

/// The Android channel of the reminders. Android 8+ shows nothing without
/// a channel; the person can tune its sound and importance in Settings.
const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
  'tafaqod.reminders',
  ServiceTexts.channelName,
  description: ServiceTexts.channelDescription,
  importance: Importance.high,
);
