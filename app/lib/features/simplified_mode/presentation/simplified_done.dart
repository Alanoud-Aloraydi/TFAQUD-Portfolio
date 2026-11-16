import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Who recorded a done task and when they pressed: its dose's or its
/// reading's record, or who said «حضرت» for its visit.
typedef SimplifiedDone = ({
  DateTime at,
  String? accountId,
  String? name,
  String? avatarCode,
});

/// The record of a done [task]; null when it has none.
SimplifiedDone? simplifiedDone(TodayTask task) =>
    switch ((task.dose?.record, task.measurement?.record, task.appointment)) {
      (final dose?, _, _) => (
        at: dose.recordedAt,
        accountId: dose.recordedByAccountId,
        name: dose.recordedByName,
        avatarCode: dose.recordedByAvatarCode,
      ),
      (_, final reading?, _) => (
        at: reading.recordedAt,
        accountId: reading.recordedByAccountId,
        name: reading.recordedByName,
        avatarCode: reading.recordedByAvatarCode,
      ),
      // An attended visit's last change is «حضرت», with who pressed it.
      (_, _, final visit?) when visit.status == AppointmentStatus.completed => (
        at: visit.updatedAt,
        accountId: visit.updatedBy?.id,
        name: visit.updatedBy?.name ?? visit.updatedByName,
        avatarCode: visit.updatedBy?.avatarCode,
      ),
      _ => null,
    };

/// «تم 4:30 مساءً»: done, at the patient's clock time it was pressed.
String simplifiedDoneAt(BuildContext context, SimplifiedDone? done) =>
    done == null
    ? context.tr('simplified_mode.status.done')
    : context.tr(
        'simplified_mode.status.done_at',
        args: <String>[simplifiedClockAt(context, done.at)],
      );

/// Who pressed it, by name alone: «سارة», or the patient's own name;
/// «أنت» when their record carries none; null when who is not known.
String? simplifiedDoneBy(
  BuildContext context,
  SimplifiedDone? done,
  SimplifiedDay day,
) {
  if (done == null) return null;
  final String name = done.name?.trim() ?? '';
  if (name.isNotEmpty) return name;
  // The server writes an id with or without its dashes, by the endpoint.
  final String? id = done.accountId?.replaceAll('-', '');
  return id != null && id == day.accountId.replaceAll('-', '')
      ? context.tr('simplified_mode.status.you')
      : null;
}
