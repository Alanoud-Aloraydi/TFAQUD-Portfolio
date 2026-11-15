import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Where a task of the simplified mode stands, in the words of its row.
///
/// A late task says how long it has been late, because «فات موعده» alone
/// does not say whether that was five minutes or five hours, which is what
/// decides whether to take it now. A done task says who recorded it, so
/// the patient knows who pressed «أخذته»: «تم · بواسطتك» when they did,
/// «تم · بواسطة سارة» when someone of the family did it for them.
String simplifiedTaskStatus(
  BuildContext context,
  TodayTask task,
  SimplifiedDay day,
  DateTime now,
) {
  if (task.status == TodayTaskStatus.done) return _doneBy(context, task, day);
  if (task.status != TodayTaskStatus.late) {
    return context.tr('simplified_mode.status.${task.status.name}');
  }
  final DateTime wall = PatientClockScope.of(context).wallTime(now);
  final int minutes = wall.difference(task.scheduledAt).inMinutes;
  if (minutes < 1) return context.tr('simplified_mode.status.late');
  return context.tr(
    'simplified_mode.status.late_by',
    args: <String>[durationWords(context, minutes)],
  );
}

String _doneBy(BuildContext context, TodayTask task, SimplifiedDay day) {
  final String done = context.tr('simplified_mode.status.done');
  final (String? id, String? name) = switch ((
    task.dose?.record,
    task.measurement?.record,
  )) {
    (final dose?, _) => (dose.recordedByAccountId, dose.recordedByName),
    (_, final reading?) => (
      reading.recordedByAccountId,
      reading.recordedByName,
    ),
    _ => (null, null),
  };
  if (id != null && id == day.accountId) {
    return '$done · ${context.tr('simplified_mode.status.by_you')}';
  }
  if (name == null || name.trim().isEmpty) return done;
  final String by = context.tr(
    'simplified_mode.status.by',
    args: <String>[name],
  );
  return '$done · $by';
}
