import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/simplified_done.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Where a task of the simplified mode stands, in the words of its row.
///
/// A late task says how long it has been late, because «فات موعده» alone
/// does not say whether that was five minutes or five hours, which is what
/// decides whether to take it now. A done task says when it was pressed
/// and who pressed «أخذته»: «تم 4:30 مساءً، بواسطتك» when the patient
/// did, «تم 4:30 مساءً، بواسطة سارة» when someone of the family did.
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
  final SimplifiedDone? done = simplifiedDone(task);
  final String at = simplifiedDoneAt(context, done);
  final String? by = simplifiedDoneBy(context, done, day);
  return by == null ? at : '$at، $by';
}
