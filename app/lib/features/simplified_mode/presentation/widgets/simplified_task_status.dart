import 'package:app/app/router/routers.dart';
import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/widgets/feedback/remind_later_check.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Where a task of the simplified mode stands, in the words of its row.
///
/// A late task says how long it has been late, because «فات موعده» alone
/// does not say whether that was five minutes or five hours, which is what
/// decides whether to take it now. A done task says when it was pressed
/// and who pressed «أخذته», by name: «تم 4:30 مساءً، سارة».
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
  final String lateText = simplifiedLate(context, task);
  if (task.kind == TodayTaskKind.appointment) return lateText;
  final DateTime wall = PatientClockScope.of(context).wallTime(now);
  final int minutes = wall.difference(task.scheduledAt).inMinutes;
  if (minutes < 1) return lateText;
  return context.tr(
    'simplified_mode.status.late_by',
    args: <String>[durationWords(context, minutes)],
  );
}

/// A task whose time came, in two words: «فات موعده» for a dose or a
/// reading; a visit waits for «حضرت», in the detailed mode's own words,
/// «تأكيد الحضور».
String simplifiedLate(BuildContext context, TodayTask task) => context.tr(
  task.kind == TodayTaskKind.appointment
      ? 'today_dashboard.status.appointment_waiting'
      : 'simplified_mode.status.late',
);

String _doneBy(BuildContext context, TodayTask task, SimplifiedDay day) {
  final SimplifiedDone? done = simplifiedDone(task);
  final String at = simplifiedDoneAt(context, done);
  final String? by = simplifiedDoneBy(context, done, day);
  return by == null ? at : '$at، $by';
}

/// «ذكّرني لاحقًا» in this mode: opens «متى أذكّرك؟» for [task], in place
/// of the reminder when [replace]. While the notifications are off it
/// stays here and says so, as the detailed mode does ([mayRemindLater]).
Future<void> openSimplifiedSnooze(
  BuildContext context,
  TodayTask task, {
  bool replace = false,
}) async {
  if (!await mayRemindLater(context) || !context.mounted) return;
  if (replace) {
    context.pushReplacement(Routes.simplifiedSnooze, extra: task);
  } else {
    await context.push(Routes.simplifiedSnooze, extra: task);
  }
}
