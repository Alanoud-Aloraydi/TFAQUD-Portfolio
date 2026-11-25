import 'package:app/core/utils/recordable_now.dart';
import 'package:app/features/simplified_mode/domain/entities/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';

/// Which task can be recorded now, and which one a reminder is about.
extension TodayScheduleRecording on TodaySchedule {
  /// The dose or measurement ([kind]) waiting now, for a reminder that
  /// names no task ([reminderTask]): the most recent one whose time came
  /// and is not recorded, else the next task when it is of [kind] and can
  /// already be recorded. Null when nothing of [kind] waits.
  TodayTask? taskToRecord(TodayTaskKind kind) {
    final TodayTask? due = tasks
        .where(
          (task) =>
              task.kind == kind &&
              task.status != TodayTaskStatus.done &&
              !task.scheduledAt.isAfter(wallNow),
        )
        .lastOrNull;
    if (due != null) return due;
    final TodayTask? coming = next;
    if (coming != null && coming.kind == kind && canRecord(coming)) {
      return coming;
    }
    return null;
  }

  /// The dose or measurement a reminder for [request] in [circleId] asks
  /// about, while it is still not recorded: that exact task by its key, or,
  /// without a key, the one of its kind waiting now ([taskToRecord]). Null
  /// when it was recorded (someone in the family may have), when it is of
  /// another circle or day, and for a visit (reminder_appointment.dart).
  TodayTask? reminderTask(ReminderRequest request, String circleId) {
    if (request.kind == TodayTaskKind.appointment) return null;
    final String? key = request.taskKey;
    if (key == null) return taskToRecord(request.kind);
    return tasks
        .where(
          (task) =>
              task.status != TodayTaskStatus.done &&
              task.snoozeKey(circleId) == key,
        )
        .firstOrNull;
  }

  /// Whether [task] can be recorded now: not resolved, and not more than an
  /// hour before its time (the rule every «اليوم» row follows).
  bool canRecord(TodayTask task) => canRecordOccurrence(
    resolved: task.status == TodayTaskStatus.done,
    scheduledAt: task.scheduledAt,
    now: wallNow,
  );
}

/// How the day stands as a whole, and the one task the home card shows.
extension TodayScheduleFocus on TodaySchedule {
  int get total => tasks.length;

  int get doneCount =>
      tasks.where((task) => task.status == TodayTaskStatus.done).length;

  TodayTask? get next =>
      tasks.where((task) => task.status == TodayTaskStatus.next).firstOrNull;

  /// The most recent dose whose time passed unrecorded.
  TodayTask? get lateDose => tasks
      .where(
        (task) =>
            task.kind == TodayTaskKind.medication &&
            task.status == TodayTaskStatus.late,
      )
      .lastOrNull;

  HomeFocus get focus {
    if (lateDose != null) return HomeFocus.lateDose;
    if (focusTask != null) return HomeFocus.task;
    if (tasks.isEmpty) return HomeFocus.empty;
    return HomeFocus.allDone;
  }

  /// The task the home card shows: the late dose, else the next task, else
  /// the most recent other task whose time passed unrecorded.
  TodayTask? get focusTask =>
      lateDose ??
      next ??
      tasks.where((task) => task.status == TodayTaskStatus.late).lastOrNull;
}
