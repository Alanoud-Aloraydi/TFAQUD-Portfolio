import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// Before «ذكّرني لاحقًا» asks for a time, in both modes: while the
/// notifications are off (the switch, or the phone's Settings) it would
/// remind of nothing, so a word says so and nothing is put off. True when
/// it may go on.
Future<bool> mayRemindLater(BuildContext context) async {
  if (!GetIt.I.isRegistered<DoseReminders>()) return true;
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  final String off = context.tr('reminders.snooze_off');
  if (await GetIt.I<DoseReminders>().canRemindLater()) return true;
  if (messenger != null) {
    AppToast.showText(messenger, off, kind: ToastKind.error);
  }
  return false;
}

/// After the time is chosen: [done] says whether the task was put off
/// (the phone may have just been refused at its own question). Says when
/// it comes again with [snoozed], or why it will not.
void sayRemindLater(
  ScaffoldMessengerState messenger,
  BuildContext context, {
  required bool done,
  required String snoozed,
}) => AppToast.showText(
  messenger,
  done ? snoozed : context.tr('reminders.snooze_off'),
  kind: done ? ToastKind.success : ToastKind.error,
);
