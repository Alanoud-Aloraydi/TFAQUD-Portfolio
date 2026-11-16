import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Who recorded a done task and when they pressed: its dose's or its
/// reading's record.
typedef SimplifiedDone = ({
  DateTime at,
  String? accountId,
  String? name,
  String? avatarCode,
});

/// The record of a done [task]; null when it has none.
SimplifiedDone? simplifiedDone(TodayTask task) =>
    switch ((task.dose?.record, task.measurement?.record)) {
      (final dose?, _) => (
        at: dose.recordedAt,
        accountId: dose.recordedByAccountId,
        name: dose.recordedByName,
        avatarCode: dose.recordedByAvatarCode,
      ),
      (_, final reading?) => (
        at: reading.recordedAt,
        accountId: reading.recordedByAccountId,
        name: reading.recordedByName,
        avatarCode: reading.recordedByAvatarCode,
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

/// «بواسطتك» when the patient pressed it, «بواسطة سارة» when someone of
/// the family did; null when who is not known.
String? simplifiedDoneBy(
  BuildContext context,
  SimplifiedDone? done,
  SimplifiedDay day,
) {
  if (done == null) return null;
  if (done.accountId != null && done.accountId == day.accountId) {
    return context.tr('simplified_mode.status.by_you');
  }
  final String? name = done.name;
  if (name == null || name.trim().isEmpty) return null;
  return context.tr('simplified_mode.status.by', args: <String>[name]);
}
