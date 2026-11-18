import 'package:app/core/services/reminders/dose_reminders.dart'
    show SharedSnooze, TaskSnooze;
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_clock_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// آ«ط³ط£ط°ظƒظ‘ط±ظƒ 2:09 ظ…ط³ط§ط،ظ‹آ» on [task] of [circleId] while this phone put it
/// off ([snoozes]); آ«ط§ظ„طھط°ظƒظٹط± ظ…ط¤ط¬ظ‘ظ„ ط¥ظ„ظ‰ 2:09 ظ…ط³ط§ط،ظ‹طŒ ظ„ظٹظ†آ» while someone else
/// in the circle did; null for any other task, or once its reminder came.
String? simplifiedSnoozed(
  BuildContext context,
  Map<String, TaskSnooze> snoozes,
  String circleId,
  TodayTask task,
) {
  if (task.status == TodayTaskStatus.done) return null;
  final TaskSnooze? snooze = snoozes[task.snoozeKey(circleId)];
  if (snooze != null) {
    return context.tr(
      'simplified_mode.snoozed_until',
      args: <String>[simplifiedClockAt(context, snooze.at)],
    );
  }
  final SharedSnooze? shared = task.dose?.snooze ?? task.measurement?.snooze;
  if (shared == null || !shared.waitsAt(DateTime.now())) return null;
  final String at = simplifiedClockAt(context, shared.remindAt);
  final String? name = shared.byName;
  return name == null
      ? context.tr('simplified_mode.snoozed_shared', args: <String>[at])
      : context.tr('simplified_mode.snoozed_by', args: <String>[at, name]);
}
